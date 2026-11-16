# TaskExample

Programa de console com tarefas em segundo plano do PascalRAL 2.0 (pacote `RALHostingTaskPackage`).

## O que ele faz

1. **Cadeia de três tarefas** (ler, contar, relatar): cada uma recebe o `Output` da anterior como `Input`, no pool de threads que todas as tarefas dividem; o programa espera a última (`WaitFor`), que é esperar a cadeia toda.
2. **Cancelamento:** uma tarefa longa é cancelada no meio, vê `Cancelled` e para; `OnCancel` avisa.
3. **Várias ao mesmo tempo:** três tarefas esperadas juntas com `TRALTask.WaitAll`.

## Como rodar

Instale/compile `PascalRAL` e `RALHostingTaskPackage`, compile e execute.

Guia: [Tarefas em segundo plano](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/tarefas).
