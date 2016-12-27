unit module NombresPropios; 

# RNP: Reconocimiento de Nombres Propios

grammar RNP {
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


class RNP-actions {
     method TOP ($/) {
         make {
             fecha => $<préambulo><fecha>.made,
             datos => $<cuerpo><datos>>>.made;
         }
    }

    method fecha($/) { make "$2-$1-$0" }
    method datos($/) { make $/.Str }
}

## algunas pruebas

# my $documento = "$*HOME/arenero/reunion.asp?p=119&r=1".IO.slurp;
# my $match = RNP.parse($documento, :actions(RNP-actions.new)).made;
# say $match<fecha>;

# for dir("$*HOME/Descargas/vozyvoto/txt") -> $documento {
#     my $match = RNP.parse($documento.IO.slurp, :actions(RNP-actions.new)).made;
#     say $match<fecha>, ' ', $documento.basename;
# }
