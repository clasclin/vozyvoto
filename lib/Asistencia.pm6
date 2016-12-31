unit module Asistencia;

# Captura los presentes

grammar Asistencia is export {
    token TOP       { ^ <enlace> ** 2 <html> $ }

    token enlace    { '<' <-[\>]>+ '>' \n }

    token html      { '<html>' \n <cabecera> \n <cuerpo> }

    token cabecera  { '<head>' \n <meta> <título> <enlace> <estilo> '</head>' }
    token meta      { '<META' <contenido> '>' \n }
    token contenido { <-[\>]>+ }
    token título    { '<title>' <texto>+ '</title>' \n }
    token texto     { <-[\<]>+ }
    token estilo    { '<style>' <texto>+ '</style>' \n }

    token cuerpo    { '<body>' \n <div> <asist> .+ }
    token div       { '<div' <-[\>]>+ '>' \n <p>+ \n '</div>' \n <p> \n }
    token p         { '<p>' [<texto> [<span>||<br>]* \s*]+ '</p>' }
    token span      { '<span' <contenido> '>' <texto>? '</span>' }
    token br        { '<br>' }
    token asist     { '<ul class="asistencia-presentes">' \n [<li> \n]+ '</ul>' \n }
    token nota      { '<i>' <texto> '</i>' }
    token li        { '<li>' <presentes> <nota>? '</li>' }
    token presentes { <-[\<]>+ }
}


class Asistencia-actions is export {
    method TOP ($/) {
        make {
            presentes => $<html><cuerpo><asist><li>>><presentes>>>.made;
        }
    }

    method presentes ($/) { make $/.Str }
}
