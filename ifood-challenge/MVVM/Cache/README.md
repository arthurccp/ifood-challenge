# Cache

A persistência de cache do app fica nesta pasta.

| Arquivo | Responsabilidade | Armazenamento |
| --- | --- | --- |
| `CodableStore.swift` | Compartilhar leitura, codificação, gravação e remoção de valores `Codable`, com chave configurável. | UserDefaults |
| `CharacterListStateStore.swift` | Ler e salvar a última consulta concluída, filtros e posição da lista. | UserDefaults: `characters.listState.v1` e `characters.listPosition.v1` |
| `ImageCache.swift` | Ler e salvar fotos na memória e em disco. | NSCache de 20 MB e diretório `Caches/CharacterImages` |

O `CharacterService` usa diretamente `CodableStore<CharacterPage>` com a chave `characters.response.v1` e descarta a resposta quando a decodificação falha. É possível injetar um store com `UserDefaults` isolado para testes. O `CharacterListViewModel` coordena `CharacterListStateStore`; o estado completo tem precedência sobre a resposta inicial ao abrir o app. Esse componente mantém as regras de versão e vínculo da rolagem. A `RemoteImageView` recebe um `ImageLoading`; a implementação `ImageLoader` coordena download e `ImageCache`.

Pesquisa e filtros não substituem a resposta inicial. O estado completo é salvo após cada página bem-sucedida, inclusive quando a consulta não tem resultados. Ele inclui a próxima página; falhas de paginação preservam os resultados e permitem repetir apenas a página pendente. A posição é vinculada ao identificador desse estado e gravada separadamente.

Os caches não expiram automaticamente. O iOS pode remover os arquivos do diretório Caches. Preserve as chaves e versões existentes ao alterar a implementação, ou defina uma migração para os dados antigos.

`CodableStore` propaga erros de decodificação para que cada consumidor aplique sua política de invalidação. A gravação informa se a codificação teve sucesso; a posição só é removida após salvar o estado. As regras de versão e vínculo da posição continuam no `CharacterListStateStore`.

O estado usa a versão 2 e mantém o mesmo identificador ao acrescentar páginas, preservando a posição salva. Uma nova pesquisa ou troca de filtros gera outro identificador e limpa a posição anterior. Estados da versão 1 são descartados com sua posição porque não indicam se existem páginas restantes; o app recarrega a primeira página. A resposta inicial antiga, sem `info`, também é descartada ao decodificar. As chaves existentes são mantidas.
