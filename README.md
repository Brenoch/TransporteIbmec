# Transporte Ibmec

Aplicativo de iPhone, feito em SwiftUI, para os alunos do Ibmec acompanharem o
transporte universitário: rotas, horários, paradas, mapa e a posição do ônibus
em tempo real. Projeto acadêmico, feito em grupo.

## Funcionalidades

**Aluno**

- cadastro, login e recuperação de senha;
- lista de "Rotas de Hoje", com a indicação de quais estão em rota;
- tela de cada rota com origem, destino, horários, paradas e mapa (MapKit);
- posição ao vivo do ônibus, lida do Firebase Realtime Database;
- carteirinha digital com QR code gerado a partir da matrícula;
- atalhos para o SAVA e o SIA;
- compartilhamento da rota e dos horários.

**Administrador**

- criar, editar, suspender e excluir rotas;
- cadastrar motoristas.

## Tecnologias

- Swift e SwiftUI
- MapKit e UserNotifications
- URLSession com `async/await` para falar com a API REST
- Firebase Realtime Database (posição dos ônibus, lida por HTTP)

## Estrutura

```text
Shared/TransporteIBMECApp.swift   ponto de entrada do app
ContentView.swift                 navegação principal
HomeAlunoView.swift               rotas do dia
RouteDetailView.swift             detalhe da rota, mapa e alerta
CarteirinhaDigitalView.swift      carteirinha com QR code
CadastroAlunoView.swift           cadastro de aluno
EsqueciSenhaView.swift            recuperação de senha
AdminViews.swift                  gestão de rotas e motoristas
Networking/                       cliente REST, autenticação e modelos
Tests iOS/                        modelo de testes do Xcode (ainda sem casos próprios)
```

A camada `Networking/` guarda o token de acesso e renova a sessão
automaticamente (`AuthManager`, `TokenStore` e `APIClient`).

## Como rodar

**Requisitos:** Mac com Xcode 13.2 ou superior. O alvo mínimo é o iOS 15.2.

```bash
open TransporteIBMEC.xcodeproj
```

Escolha um simulador de iPhone e execute (`⌘R`).

O app precisa de uma API REST para login e rotas. O endereço fica em
`Networking/AppConfig.swift` (`baseURL`) e, por padrão, é
`http://localhost:8000/api/v1`. **Essa API não faz parte deste repositório**,
então, sem ela, as telas de login e de rotas não carregam dados.

## Limitações conhecidas

- O alerta "Ônibus a caminho" é um protótipo: a notificação local dispara
  depois de 15 segundos e ainda não está ligada à posição real do ônibus.
- A API REST usada pelo app é externa a este repositório.
