<#
    Desfaz TUDO o que a preparacao do http.sys deixou nesta maquina.

    O botao "Preparar http.sys" (deste exemplo e do demo RALDemoHTTP2) cria um
    certificado autoassinado, o torna confiavel, amarra na porta e reserva a
    URL. Rodado varias vezes, ou por versoes diferentes do script, deixa
    certificados empilhados na loja e amarracoes de certificados diferentes na
    MESMA porta - e ai o http.sys atende com o mais especifico, que pode nao ser
    o que o cliente espera. Este script devolve a maquina ao estado de antes.

    O que ele remove, nesta ordem:

      1. as amarracoes de certificado (netsh http delete sslcert), por porta e
         tambem por certificado - assim pega uma amarracao esquecida em outra
         porta;
      2. as reservas de URL (netsh http delete urlacl) das portas;
      3. os certificados autoassinados de "localhost" e do nome da maquina, das
         lojas LocalMachine\My e LocalMachine\Root.

    Uso:
      .\DesfazerPreparacaoHttps.ps1                    # pergunta as portas, mostra e confirma
      .\DesfazerPreparacaoHttps.ps1 -Listar            # so' mostra, nao apaga nada
      .\DesfazerPreparacaoHttps.ps1 -Portas 8443,9443  # sem perguntar as portas
      .\DesfazerPreparacaoHttps.ps1 -Force             # apaga sem confirmar

    Sem -Portas, ele PERGUNTA quais portas limpar - nao existe porta padrao,
    de proposito: limpar a porta errada apaga a preparacao de outro servico.

    Precisa de administrador; se nao estiver, ele mesmo pede a elevacao.
#>

[CmdletBinding()]
param(
    [int[]] $Portas,
    [switch] $Listar,
    [switch] $Force
)

$ErrorActionPreference = 'Continue'

# ------------------------------------------------------------------ portas --
# Perguntadas ANTES da elevacao: a janela elevada e' outra, e as portas vao
# para ela pela linha de comando - quem responde e' quem rodou o script.
while (-not $Portas) {
    $resposta = Read-Host 'Quais portas desfazer? (separadas por virgula, ex.: 8443 ou 8443,9443)'
    $lidas = @()
    $ok = $true
    foreach ($parte in ($resposta -split '[,;\s]+' | Where-Object { $_ })) {
        $n = 0
        if ([int]::TryParse($parte, [ref]$n) -and $n -ge 1 -and $n -le 65535) {
            $lidas += $n
        }
        else {
            Write-Host "  '$parte' nao e' uma porta (1 a 65535)." -ForegroundColor Red
            $ok = $false
        }
    }
    if ($ok -and $lidas.Count -gt 0) {
        $Portas = $lidas | Select-Object -Unique
    }
    elseif ($lidas.Count -eq 0 -and $ok) {
        Write-Host '  Informe ao menos uma porta.' -ForegroundColor Red
    }
}

# ---------------------------------------------------------------- elevacao --
$souAdmin = ([Security.Principal.WindowsPrincipal] `
             [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $souAdmin -and -not $Listar) {
    Write-Host 'Preciso de administrador. Pedindo elevacao...' -ForegroundColor Yellow
    # $args e' variavel automatica do PowerShell - nao se escreve nela
    $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
                    '-Portas', ($Portas -join ','))
    if ($Force) { $argumentos += '-Force' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argumentos
    return
}

Write-Host ''
Write-Host 'Desfazendo a preparacao do http.sys' -ForegroundColor Cyan
Write-Host ("portas: " + ($Portas -join ', '))
Write-Host ''

# ------------------------------------------------- 1. o que existe hoje -----

<#  O netsh fala o idioma do Windows, entao NADA aqui casa rotulo: cada bloco
    e' separado por linha em branco, o endereco e' o valor da PRIMEIRA linha do
    bloco e a impressao digital e' o unico token de 40 hexadecimais. Funciona
    em portugues, ingles ou qualquer outro. #>
function Get-SslBindings {
    $texto = (netsh http show sslcert 2>&1 | Out-String)
    $blocos = $texto -split "(\r?\n){2,}"
    foreach ($bloco in $blocos) {
        $linhas = $bloco -split "\r?\n" | Where-Object { $_ -match '\S' }
        if (-not $linhas) { continue }
        $hash = $null
        foreach ($l in $linhas) {
            $m = [regex]::Match($l, '\b([0-9a-fA-F]{40})\b')
            if ($m.Success) { $hash = $m.Groups[1].Value.ToLower(); break }
        }
        if (-not $hash) { continue }
        # o endereco e' o que vem depois do ultimo " : " da primeira linha
        $primeira = $linhas[0]
        $idx = $primeira.LastIndexOf(' : ')
        if ($idx -lt 0) { continue }
        $endereco = $primeira.Substring($idx + 3).Trim()
        if (-not $endereco) { continue }
        [pscustomobject]@{
            Endereco = $endereco
            Hash     = $hash
            # um endereco que comeca por digito ou '[' e' IP; o resto e' nome (SNI)
            PorNome  = -not ($endereco -match '^(\d|\[)')
        }
    }
}

function Get-UrlAcls {
    $texto = (netsh http show urlacl 2>&1 | Out-String)
    [regex]::Matches($texto, 'https?://[^\s]+/') | ForEach-Object { $_.Value }
}

function Get-CertsDaPreparacao {
    $nomes = @('localhost', $env:COMPUTERNAME)
    foreach ($loja in @('My', 'Root')) {
        Get-ChildItem "Cert:\LocalMachine\$loja" -ErrorAction SilentlyContinue |
            Where-Object {
                # autoassinado (emissor = titular) E com um dos nomes que a
                # preparacao usa - nunca um certificado de CA de verdade
                $_.Subject -eq $_.Issuer -and
                (($nomes | ForEach-Object { "CN=$_" }) -contains $_.Subject)
            } |
            ForEach-Object {
                [pscustomobject]@{
                    Loja       = $loja
                    Thumbprint = $_.Thumbprint
                    Subject    = $_.Subject
                    NotAfter   = $_.NotAfter
                    Caminho    = "Cert:\LocalMachine\$loja\$($_.Thumbprint)"
                }
            }
    }
}

$bindings = @(Get-SslBindings)
$certs    = @(Get-CertsDaPreparacao)
$nossos   = @($certs | ForEach-Object { $_.Thumbprint.ToLower() } | Select-Object -Unique)

# amarracao a remover: a que esta' numa das portas, OU a que aponta para um
# certificado da preparacao (pega uma esquecida em outra porta)
$bindAlvo = @($bindings | Where-Object {
    $porPorta = $false
    foreach ($p in $Portas) { if ($_.Endereco -match ":$p$") { $porPorta = $true } }
    $porPorta -or ($nossos -contains $_.Hash)
})

$aclAlvo = @(Get-UrlAcls | Where-Object {
    $u = $_
    ($Portas | Where-Object { $u -match ":$($_)/" }).Count -gt 0
} | Select-Object -Unique)

Write-Host 'Amarracoes de certificado (sslcert):' -ForegroundColor Yellow
if ($bindAlvo.Count -eq 0) { Write-Host '  nenhuma' }
else { $bindAlvo | ForEach-Object { Write-Host ("  {0,-24} -> {1}" -f $_.Endereco, $_.Hash) } }

Write-Host ''
Write-Host 'Reservas de URL (urlacl):' -ForegroundColor Yellow
if ($aclAlvo.Count -eq 0) { Write-Host '  nenhuma' }
else { $aclAlvo | ForEach-Object { Write-Host "  $_" } }

Write-Host ''
Write-Host 'Certificados autoassinados da preparacao:' -ForegroundColor Yellow
if ($certs.Count -eq 0) { Write-Host '  nenhum' }
else { $certs | ForEach-Object { Write-Host ("  {0,-5} {1}  {2}  vence {3:dd/MM/yyyy}" -f $_.Loja, $_.Thumbprint, $_.Subject, $_.NotAfter) } }

if ($Listar) {
    Write-Host ''
    Write-Host 'Modo -Listar: nada foi apagado.' -ForegroundColor Green
    return
}

if ($bindAlvo.Count -eq 0 -and $aclAlvo.Count -eq 0 -and $certs.Count -eq 0) {
    Write-Host ''
    Write-Host 'Nada a desfazer.' -ForegroundColor Green
    if (-not $Force) { Read-Host 'ENTER para fechar' }
    return
}

if (-not $Force) {
    Write-Host ''
    $r = Read-Host 'Apagar tudo isso? (s/N)'
    if ($r -ne 's' -and $r -ne 'S') { Write-Host 'Cancelado.'; return }
}

# ------------------------------------------------------------- 2. apaga -----

Write-Host ''
foreach ($b in $bindAlvo) {
    $arg = if ($b.PorNome) { "hostnameport=$($b.Endereco)" } else { "ipport=$($b.Endereco)" }
    $saida = (netsh http delete sslcert $arg 2>&1) -join ' '
    Write-Host ("sslcert {0,-24}: {1}" -f $b.Endereco, $saida.Trim())
}

foreach ($u in $aclAlvo) {
    $saida = (netsh http delete urlacl "url=$u" 2>&1) -join ' '
    Write-Host ("urlacl  {0,-24}: {1}" -f $u, $saida.Trim())
}

foreach ($c in $certs) {
    try {
        Remove-Item $c.Caminho -Force -ErrorAction Stop
        Write-Host ("cert    {0,-5} {1}: removido" -f $c.Loja, $c.Thumbprint)
    }
    catch {
        Write-Host ("cert    {0,-5} {1}: FALHOU - {2}" -f $c.Loja, $c.Thumbprint, $_.Exception.Message)
    }
}

Write-Host ''
Write-Host 'Pronto. A maquina esta como antes da preparacao.' -ForegroundColor Green
Write-Host 'Para voltar a usar o modo http.sys, rode "Preparar http.sys" no servidor.'
if (-not $Force) { Read-Host 'ENTER para fechar' }
