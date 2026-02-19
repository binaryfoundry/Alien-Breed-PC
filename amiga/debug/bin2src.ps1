# bin2src source destination bytesperline linespergroup

param ([Parameter(Mandatory)]$i, $o, $l, $g)

[byte[]]$data = [System.IO.File]::ReadAllBytes($i) 
[string[]]$hex = [System.BitConverter]::ToString($data).split('-')
[string]$src = ""
[string]$sep = ""
[int]$lcounter = 0
[int]$gcounter = $g
foreach ($item in $hex) {
    if($lcounter -eq 0) {
        if( $g -ne 0) {
            $gcounter -= 1
            if( $gcounter -lt 0) {
                $src += "`n"
                $gcounter = $g
            }     
        }
        $src += "`n dc.b "
        $sep = "" 
        $lcounter = $l
    } else {
        $sep = ","
    }
    $src += $sep + "$" + $item
    $lcounter -= 1
}
[System.IO.File]::WriteAllText($o, $src, [System.Text.Encoding]::ASCII)