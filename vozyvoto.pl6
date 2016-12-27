#!/usr/bin/env perl6
#
# voz-y-voto.pl6 - reinventado la rueda :)
#

use v6;
use lib 'lib';
use NombresPropios;

my Str $voz-y-voto  = "$*HOME/voz_y_voto";
my Str $reuniones   = 'reuniones';
my Str $asistencia  = 'asistencia';
my Str $textos      = 'textos';
my Str $presentes   = 'presentes';


sub MAIN (Str $archivo, Str $guardar-en = $voz-y-voto) {

    $guardar-en.IO.d
        ?? chdir $guardar-en
        !! (mkdir $guardar-en; chdir $guardar-en);

    directorios-del-proyecto;

    # obtener asistencia y reuniones

    my Str @reuniones-links;
    my Str @asistencia-links;
    my Str $url := 'http://www1.hcdn.gov.ar/sesionesxml/';

    my Regex $reunion-regex    = /:r ('reunion.asp?p=' \d+) ('&amp;r=' \d+) /;
    my Regex $asistencia-regex = /:r ('asistencia.asp?per=' \d+) ('&amp;reunion=' \d+) /;

    for "$archivo".IO.lines -> Str $línea {
        given $línea {
            when .match($reunion-regex)    {
                @reuniones-links.push:   join '', $url, $0.Str, $1.subst('&amp;', '&')
            }
            when .match($asistencia-regex) {
                @asistencia-links.push: join '', $url, $0.Str, $1.subst('&amp;', '&')
            }
        }
    }

    descargar(@reuniones-links, $reuniones)
    descargar(@asistencia-links, $asistencia);

    # presentes

    ## tengo que implementar mi propia manera de parsear los presentes
    ## Gumbo no funciona

    # textos

    my HyperSeq $reuniones-archivos = dir($reuniones).race;
    $reuniones-archivos.map(&extraer-texto);

    # nombres propios

    # funciónes auxiliares

    sub descargar (@enlaces where Array, Str $directorio) {
        chdir "$directorio" or die "$!";
        for @enlaces -> Str $enlace {
            my $guardar-como = $enlace.split('/').tail;
            unless $guardar-como.IO.f {
                my Proc $wget = run 'wget', '-O', '-', "$enlace", :out;
                my Proc $utf8 = run 'iconv', '-f', 'LATIN1', 't', 'utf8', :in($wget.out), :out;
                spurt "$guardar-como", $utf8.out.lines;
                sleep 2;
            }
        }
    }


    sub extraer-texto ($nombre) {
        run 'pandoc', '+RTS', '-K64m', '-RTS', '-f', 'html', '-t', 'plain', "$nombre", '-o',
            "$textos/$nombre";
    }


    sub crear-directorio (Str $directorio) {
        mkdir $directorio unless $directorio.IO.d
    }


    sub directorios-del-proyecto () {
        crear-directorio($reuniones);
        crear-directorio($asistencia);
        crear-directorio($presentes);
        crear-directorio($textos);
    }
}
