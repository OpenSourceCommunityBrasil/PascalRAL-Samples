# JobQueueExample

Programa de console que usa a fila de jobs persistente do PascalRAL 2.0 (pacote `RALHostingJobQueuePackage`: `TRALJobQueue`, `RALJobStore`). Os jobs ficam em arquivos na pasta `jobs` ao lado do executável e o programa sai ao terminar.

## O que ele faz

1. Cria a fila com 2 trabalhadores, 4 tentativas no máximo, espera de 500 ms entre tentativas e verificação a cada 200 ms.
2. Registra quatro manipuladores: `email` (sempre funciona), `instavel` (falha nas tentativas 1 e 2 e passa na 3), `limite` (pede nova tentativa em 1 s com `RetryAfter`) e `permanente` (desiste na hora com `GiveUp`).
3. Enfileira 3 e-mails, um job de cada outro tipo, um e-mail com atraso de 2 s (`ADelay`) e outro agendado com `EnqueueAt` para daqui a 3 s.
4. Ativa a fila, espera esvaziar, lista os jobs mortos com `List` + `ReadJob` (último erro e tentativas) e os remove com `PurgeDead`.

Os eventos `OnJobDone`, `OnJobFailed` e `OnJobDead` rodam nas threads de trabalho; por isso a saída é protegida por uma seção crítica.

Os jobs sobrevivem a uma reinicialização: basta criar a fila de novo sobre a mesma pasta. Para reprocessar um job morto use `Requeue`/`RequeueAll`.

## Como rodar

Instale/compile `PascalRAL` e `RALHostingJobQueuePackage`, compile `RALJobQueueExample.dpr` e execute.
