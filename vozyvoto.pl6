#!/usr/bin/env perl6
#
# voz-y-voto.pl6 - reinventado la rueda :) 
#

use v6;
use Selenium::WebDriver::Chrome;


my $descargas   = "%*ENV<HOME>/Descargas/vyv-prueba";
my $asistencias = "$descargas/asistencias";
my $asis-utf8   = "$descargas/asistencias-utf8";
my $reuniones   = "$descargas/reuniones";
my $reu-html    = "$*CWD/reuniones.html";
my $hombres     = "$*CWD/nombres-masculinos.txt";
my $mujeres     = "$*CWD/nombres-femeninos.txt";
my $dir-vyv     = "$*CWD";
my $fechas      = "$descargas/fechas.tsv";
my $genero      = "$descargas/genero";
my $araña       = "$descargas/araña";
my $txt         = "$descargas/txt";
my $lda         = "$descargas/listas-de-asistencias";


sub MAIN(:$paso) {
    # FALTA: redefinir USAGE 

    my $url-base = 'http://www1.hcdn.gov.ar/sesionesxml/'; 
    crear-ingresar($descargas);

    given $paso {
        when 'descargar'         { descargar($url-base) }
        when 'extraer-reuniones' { extraer-reuniones($url-base) }
        when 'extraer-texto'     { extraer-texto() }
        when 'asistencias'       { asistencias($url-base) }
        when 'determinar-genero' { determinar-genero() }
        when 'capturar-fechas'   { capturar-fechas() }
        when 'csv-a-tsv'         { csv-a-tsv() }
        when 'enlazar'           { enlazar() }
        default {
            descargar($url-base);
            extraer-reuniones($url-base);
            extraer-texto();
            asistencias($url-base);
            determinar-genero();
            capturar-fechas();
            csv-a-tsv();
            enlazar(); 
        }
    }
}

# funciones auxiliares

sub crear-ingresar($dir) { "$dir".IO.d ?? chdir $dir !! (mkdir $dir; chdir $dir) }


sub convertir-a-utf8($directorio, $destino) {
    say "Convirtiendo a utf8";

    mkdir $destino unless "$destino".IO.d;

    for dir($directorio) -> $archivo {
        unless $archivo ~~ /:i '.' log $/ {
            my $nombre = $archivo.basename;
            run 'iconv', '-f', 'LATIN1', '-t', 'utf8', "$archivo", '-o', "$destino/$nombre";
        } 
    } 
}


sub descarga-de($regex, $url) {
    # se usa en la descarga de reuniones y asistencias
    my @datos;
    my $archivo-reuniones = open "$reu-html", :r;
    for "$archivo-reuniones".IO.lines -> $línea {
        if $línea.match($regex) {
            my $amp = $1.Str.subst(/ '&amp;' /, '&');
            my $datos = join '', $url, $0.Str, $amp;
            @datos.push($datos);
        }
    }
    close $archivo-reuniones;

    for @datos -> $enlace {
        my $reunión = $enlace.basename;
        my $descarga = run 'wget', '--limit-rate=100k', '-aroa.log', "$enlace"; sleep 2;
        next if $descarga.exitcode == -1;
    }
}


# funciones principales 
 
sub descargar($url-base) {
    say 'Descargando las reuniones...';

    crear-ingresar($descargas);

    my $reuniones-shtml = 'reuniones.shtml#';
    my $url = join '', $url-base, $reuniones-shtml; 

    my $navegador = Selenium::WebDriver::Chrome.new;
    $navegador.url($url);
    my $html = $navegador.source();
    spurt 'reuniones.html', "$html";

    $navegador.quit();
}


sub extraer-reuniones($url-base) {
    say "Extrayendo reuniones...";

    crear-ingresar($araña);

    my $regex-reuniones = / (reunion '.' asp '?' 'p=' \d**3) ('&amp;r=' \d+) /;
    descarga-de($regex-reuniones, $url-base);

    convertir-a-utf8($araña, $reuniones);
}


sub extraer-texto() {
    say 'Extrayendo el texto';

    crear-ingresar($txt); 

    for dir($reuniones) -> $reunión {
        my $archivo = $reunión.basename;
        run 'pandoc', '-f', 'html', '-t', 'plain', "$reunión", '-o', "$archivo";
    } 
}


sub asistencias($url-base) {
    say 'Generando datos de asistencias';

    crear-ingresar($asistencias);

    my $regex-asistencias = / (asistencia '.' [asp || php] '?') (.+?) \" /;
    descarga-de($regex-asistencias, $url-base);

    convertir-a-utf8($asistencias, $asis-utf8);

    crear-ingresar($lda);
    for dir($asis-utf8) -> $archivo {
        my @personas;
        for "$archivo".IO.lines -> $línea {
            if $línea ~~ / ^'<li>' (.+?) '<' / {
                @personas.push($0.Str);
            }
        }
        my $lda-txt = open "$lda/$nombre", :w;
        for @personas -> $persona { $lda-txt.say($persona) }
        close $lda-txt;
    }
}


sub determinar-genero() {
    # solo se tiene en cuenta el primer nombre para determinar si 
    # es hombre o mujer
    say 'Determinado el genero según el nombre';

    chdir $descargas;

    my @hombres = "$hombres".IO.lines;
    my %hombres = map { uc($_) => 1 }, @hombres;

    my @mujeres = "$mujeres".IO.lines;
    my %mujeres = map { uc($_) => 1 }, @mujeres;

    crear-ingresar($genero);

    for dir($lda) -> $archivo {
        my @líneas;
        my @indefinidos;
        for "$archivo".IO.lines -> $línea {
            if $línea ~~ / ^\w+ / {
                my $nombres = $línea.split(', ')[1];
                my ($primer-nombre, *@) = $nombres.split(/\s/);
                given $primer-nombre {
                    when %hombres{$primer-nombre}:exists { @líneas.push("$línea\tm") }
                    when %mujeres{$primer-nombre}:exists { @líneas.push("$línea\tf") }
                    default { @indefinidos.push("$línea\tI") }
                }
            } 
        }
        my $fh = open "$nombre", :w;
        for @líneas -> $línea { $fh.say($línea) }
        close $fh;
        
        my $indef = open "nombres-no-reconocidos.txt", :w;
        for @indefinidos -> $línea { $indef.say($línea) }
        close $indef;
    }
}


sub capturar-fechas() {
    say 'Obteniendo las fechas para cada sesión';

    crear-ingresar($reuniones);

    my @fechas;
    for dir($reuniones) -> $archivo {
        my $reunión = $nombre.split('p=')[1];
        for "$archivo".IO.lines -> $línea {
            if $línea ~~ / subtit '">' (\d**2 '/' \d**2 '/' \d**4) / {
                my $fecha = $0.Str;
                @fechas.push("$reunión\t$fecha");
            }
        } 
    }
    my $fechas-fh = open "$fechas", :w;
    for @fechas -> $fecha { $fechas-fh.say($fecha) }
    close $fechas-fh;
}


sub csv-a-tsv() {
    say 'Convirtiendo a tsv';
    chdir $dir-vyv;

    run 'ant', 'build';
    run 'ant', 'run';

    move 'output.csv', 'ner.csv';
    # parcialmente implementado
}


sub enlazar() {
    say 'Juntando las partes';
    # no implementado
}   
