# Saborê

Aplicativo mobile de receitas desenvolvido em Flutter. O Saborê permite descobrir receitas, pesquisar pelo nome, consultar ingredientes e modo de preparo e salvar receitas favoritas durante a sessão.

## Funcionalidades

- Carregamento automático das receitas na primeira abertura.
- Listagem rolável com nome, imagem, tempo e avaliação.
- Pesquisa remota pelo nome, com tratamento de espaços e consultas vazias.
- Estados de carregamento, erro, nova tentativa e ausência de resultados.
- Tela de detalhes com ingredientes, instruções, tempo, porções, avaliação e tipo de refeição.
- Favoritos em memória, sem duplicatas, com acesso pela barra de navegação.
- Imagem alternativa quando a foto não existe ou não pode ser carregada.

## API

Os dados são obtidos da API pública [DummyJSON Recipes](https://dummyjson.com/docs/recipes):

- `GET /recipes`: listagem inicial.
- `GET /recipes/search?q=termo`: pesquisa por nome.
- `GET /recipes/{id}`: detalhes da receita.

A opção usada para detalhes é consumir o objeto completo da resposta da API sempre que ele já estiver disponível na listagem ou pesquisa. Caso ingredientes ou instruções estejam ausentes, o aplicativo faz uma consulta específica em `/recipes/{id}`.

## Tecnologias

- Flutter 3.47.7
- Dart 3.13.5
- pacote `http` 1.6.0

## Como executar

Pré-requisitos:

- Flutter SDK instalado e configurado.
- Emulador Android/iOS ou dispositivo conectado.

```bash
flutter pub get
flutter run
```

Para executar os testes:

```bash
flutter test
```
