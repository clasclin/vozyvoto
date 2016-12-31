unit module NombresPropios;

# RNP: Reconocimiento de Nombres Propios

grammar RNP is export {
    token TOP       { ^ <préambulo> <cuerpo> $ }

    token préambulo { <líneas>+ <fecha> [<líneas>+ <separador>] ** 2 }
    token líneas    { <texto> || <vacía> }
    token texto     { <-[ / \n * ]>* \n }
    token vacía     { \n }
    token fecha     { ^^ (\d**^3) '/' (\d**2) '/' (\d**4) $$ }
    token separador { ^^ '* * * * *' $$ }

    token cuerpo    { [<datos>* \n]+ }
    token datos     { <[ \N ]>+ }
}


class RNP-actions is export {
    method TOP ($/) {
        make {
            fecha => $<préambulo><fecha>.made,
            datos => $<cuerpo><datos>>>.made;
        }
    }

    method fecha($/) { make "$2-$1-$0" }
    method datos($/) { make $/.Str }
}
