# CREATED BY: Christopher Neuner
# DESCRIPTION: This script creates a comma-separated output of replication sets using, as input, two 
#              files (source and target) containing the output of the EMC RecoverPoint "get_san_volumes" command.
# CREATED ON: 01/18/2016
# UPDATED ON: 03/29/2016
# DEPENDENCIES: Export two files, one for each site, using 'get_san_volumes' command in RecoverPoint ssh console.
# USE: .\rpa-vol-report.ps1 "<source_path>" "<target_path>"
#        .\rpa-vol-report.ps1 .\src_san_vols.txt .\tgt_san_vols.txt > out.csv

Param(
  [string]$src="", #source volume file (output of get_san_volumes)
  [string]$tgt="" #target volume list (output of get_san_volumes)
)

while (($src -eq "") -OR  -not(Test-Path $VolFilePath))
{
	$src = Read-Host "Enter path to source list"
	
}

while (($tgt -eq "") -OR  -not(Test-Path $src2))
{
	$tgt = Read-Host "Enter path to target list"
}

######################################################################################
###	Populate arrays for src

$VolFileText_AR = @()
$VolFileText = (Get-Content $src) -join "`n"
if ($VolFileText -like "*Volumes:*")
{
	$VolFileText_AR = ($VolFileText.substring($VolFileText.lastindexof("Volumes:"))) -split "`n"
}
else
{
	$VolFileText_AR = $VolFileText -split "`n"
}
$UID = @()
$NAME = @()
$REPINFO = @()
$ARRSER = @()
$SIZE = @()
$UID = $VolFileText_AR | Select-String -Pattern "UID:"
$NAME = $VolFileText_AR | Select-String -Pattern "Name:"
$REPINFO = $VolFileText_AR | Select-String -Pattern "Replication info:"
$ARRSER = $VolFileText_AR | Select-String -Pattern "Array Serial:"
$SIZE = $VolFileText_AR | Select-String -Pattern "Size:"

$arUID = @()
$arNAME = @()
$arREPCG = @()
$arREPSET = @()
$arARRSER = @()
$arSIZE = @()

foreach ($u in $UID)
{
	$u_s = $u.tostring()
	$arUID += $u_s.substring($u_s.lastindexof(':')+2).replace(',',':')
}

foreach ($n in $NAME)
{
	$n_s = $n.tostring()
	$arNAME += $n_s.substring($n_s.lastindexof(':')+2)
}

foreach ($r in $REPINFO)
{
	$r_s = $r.tostring()
	if ($r_s.contains("Replication info: N/A") -or $r_s.contains("Replication info: repository volume"))
	{
		$arREPCG += ""
		$arREPSET += ""
	}
	else
	{
		$arREPCG += $r_s.substring($r_s.lastindexof(':')+3, $r_s.indexof(',')-$r_s.lastindexof(':')-3)
		$arREPSET += $r_s.substring($r_s.lastindexof(',')+2, $r_s.lastindexof(']')-$r_s.lastindexof(',')-2)
	}
}

foreach ($a in $ARRSER)
{
	$a_s = $a.tostring()
	$arARRSER += $a_s.substring($a_s.lastindexof(':')+2)
}

foreach ($s in $SIZE)
{
	$s_s = $s.tostring()
	$arSIZE += $s_s.substring($s_s.lastindexof(':')+2)
}

######################################################################################
###	Populate arrays for tgt

$VolFileText2_AR = @()
$VolFileText2 = (Get-Content $tgt) -join "`n"
if ($VolFileText2 -like "*Volumes:*")
{
	$VolFileText2_AR = ($VolFileText2.substring($VolFileText2.lastindexof("Volumes:"))) -split "`n"
}
else
{
	$VolFileText2_AR = $VolFileText2 -split "`n"
}
$UID = $VolFileText2_AR | Select-String -Pattern "UID:"
$NAME = $VolFileText2_AR |Select-String -Pattern "Name:"
$REPINFO = $VolFileText2_AR |Select-String -Pattern "Replication info:"
$ARRSER = $VolFileText2_AR |Select-String -Pattern "Array Serial:"
$SIZE = $VolFileText2_AR |Select-String -Pattern "Size:"

$arUID2 = @()
$arNAME2 = @()
$arREPCG2 = @()
$arREPSET2 = @()
$arARRSER2 = @()
$arSIZE2 = @()

foreach ($u in $UID)
{
	$u_s = $u.tostring()
	$arUID2 += $u_s.substring($u_s.lastindexof(':')+2).replace(',',':')
}

foreach ($n in $NAME)
{
	$n_s = $n.tostring()
	$arNAME2 += $n_s.substring($n_s.lastindexof(':')+2)
}

foreach ($r in $REPINFO)
{
	$r_s = $r.tostring()
	if ($r_s.contains("Replication info: N/A") -or $r_s.contains("Replication info: repository volume"))
	{
		$arREPCG2 += ""
		$arREPSET2 += ""
	}
	else
	{
		$arREPCG2 += $r_s.substring($r_s.lastindexof(':')+3, $r_s.indexof(',')-$r_s.lastindexof(':')-3)
		$arREPSET2 += $r_s.substring($r_s.lastindexof(',')+2, $r_s.lastindexof(']')-$r_s.lastindexof(',')-2)
	}
}

foreach ($a in $ARRSER)
{
	$a_s = $a.tostring()
	$arARRSER2 += $a_s.substring($a_s.lastindexof(':')+2)
}

foreach ($s in $SIZE)
{
	$s_s = $s.tostring()
	$arSIZE2 += $s_s.substring($s_s.lastindexof(':')+2)
}

######################################################################################
###	Compare arrays and create comma-separated output

"CG,RSET,NAME (SRC),UID (SRC),ARRAY_SERIAL (SRC),SIZE (SRC),NAME (TGT),UID (TGT),ARRAY_SERIAL (TGT),SIZE (TGT)"

for($i=0; $i -lt $arUID.length; $i++)
{
	if ($arREPSET[$i].tostring().contains("RSet"))
	{
		for($i2=0; $i2 -lt $arUID2.length; $i2++)
		{
			if (($arREPCG[$i].tostring().equals($arREPCG2[$i2].tostring())) -and ($arREPSET[$i].tostring().equals($arREPSET2[$i2].tostring())) -and ($arREPCG[$i] -ne ''))
			{
				"$($arREPCG[$i].tostring()),$($arREPSET[$i].tostring()),$($arNAME[$i].tostring()),$($arUID[$i].tostring()),$($arARRSER[$i].tostring()),$($arSIZE[$i].tostring()),$($arNAME2[$i2].tostring()),$($arUID2[$i2].tostring()),$($arARRSER2[$i2].tostring()),$($arSIZE2[$i2].tostring())"
			}
		}
	}
}
