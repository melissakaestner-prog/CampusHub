# CampusHub

Aplicação iOS de gestão académica para uma instituição de ensino superior, desenvolvida como **trabalho final da disciplina de Desenvolvimento iOS** (Mestrado em Dispositivos Móveis e Multimédia).

## O problema

Numa faculdade onde os docentes são pagos à hora, hoje:

- Não existe um calendário formal de aulas que professores e alunos possam consultar — o secretário envia a alocação por email e o controlo passa a ser manual;
- O lançamento de horas é feito de forma informal (o coordenador pede as horas por email no fim do mês), obrigando cada docente a manter uma folha de cálculo própria;
- A secretaria não tem uma ferramenta que valide conflitos ao alocar docentes a unidades curriculares.

O **CampusHub** centraliza estes três fluxos numa única aplicação com três perfis:

| Perfil | Funcionalidades |
|---|---|
| **Professor** | Consulta o seu horário; regista horas letivas; vê o resumo mensal de horas (o valor a comunicar ao coordenador). |
| **Aluno** | Consulta a grelha horária, com pesquisa por UC, professor ou turma e filtro por dia da semana. |
| **Secretaria** | Aloca professores a unidades curriculares (dia, hora, sala, turma), com validação automática de conflitos de professor e de sala. |

## Ecrãs (mín. 3, com navegação coerente)

1. **Horário** — `List` agrupada por dia da semana, com pesquisa (`.searchable`), filtro por dia, pull-to-refresh e estados de carregamento/vazio/erro → navegação para…
2. **Detalhe da aula** — informação completa da UC, professor, sala e turma;
3. **Horas letivas** (perfil professor) — resumo mensal + lista de registos; folha modal para registar horas;
4. **Alocação** (perfil secretaria) — formulário de alocação com validação e feedback de conflito (HTTP 409);
5. **Definições** — perfil ativo, tema claro/escuro (persistido em `UserDefaults` via `@AppStorage`) e informação da app.

## API utilizada

API REST **desenvolvida no próprio projeto** (permitido pelo enunciado), disponível na pasta [`backend/`](backend/). Node.js + Express, com persistência em ficheiro JSON.

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/api/professors` | Lista de professores |
| GET | `/api/units` | Lista de unidades curriculares |
| GET | `/api/schedule` | Horário completo (filtros opcionais `professorId`, `classGroup`) |
| POST | `/api/schedule` | Cria alocação; devolve **409** em conflito de professor/sala |
| DELETE | `/api/schedule/:id` | Remove uma alocação |
| GET | `/api/timesheets?professorId=` | Registos de horas de um professor |
| POST | `/api/timesheets` | Regista horas letivas |

## Tecnologias e versões

| Tecnologia | Versão | Uso |
|---|---|---|
| Swift | 5.9+ | Linguagem |
| SwiftUI | iOS 17+ | Interface (com macro `@Observable`) |
| SwiftData | iOS 17+ | Persistência local / funcionamento offline |
| Swift Concurrency | async/await | Todas as operações assíncronas |
| Swift Testing | Xcode 16+ | Testes unitários (`@Test` / `#expect`) |
| Node.js + Express | Node 18+ / Express 4 | API REST de suporte |
| XcodeGen | 2.x | Geração do `.xcodeproj` a partir de `project.yml` |

Sem dependências de terceiros na app iOS — apenas frameworks da Apple.

## Instruções de execução

### 1. Backend (obrigatório para o primeiro carregamento)

```bash
cd backend
npm install
npm start
```

A API fica disponível em `http://127.0.0.1:3000`. A base de dados (`db.json`) é criada automaticamente a partir de `seed.json` no primeiro arranque.

### 2. App iOS (requer macOS + Xcode 16+)

Com [XcodeGen](https://github.com/yonaskolb/XcodeGen) instalado (`brew install xcodegen`):

```bash
xcodegen generate
open CampusHub.xcodeproj
```

Em alternativa, criar manualmente um projeto iOS App (SwiftUI, iOS 17) no Xcode e arrastar as pastas `CampusHub/` e `CampusHubTests/` para os targets respetivos, ativando `NSAllowsLocalNetworking` no Info.plist.

Executar no **simulador** (o `127.0.0.1` aponta para o Mac anfitrião). Para testar o modo offline: carregar os dados uma vez, parar o backend (ou ativar o Network Link Conditioner) e reabrir a app — o horário e os registos continuam disponíveis a partir do SwiftData.

### 3. Testes

`Cmd+U` no Xcode, ou:

```bash
xcodebuild test -scheme CampusHub -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Decisões arquiteturais

Detalhe completo (com diagrama) em [`docs/arquitetura.pdf`](docs/arquitetura.pdf). Resumo:

- **MVVM + camadas** — `Presentation` (Views SwiftUI + ViewModels `@Observable`), `Domain` (modelos puros, protocolos dos repositórios, erros tipados) e `Data` (rede, persistência, repositórios). O domínio não conhece SwiftUI, URLSession nem SwiftData.
- **Protocolos + injeção por inicializador** — `HTTPClientProtocol`, `LocalStoreProtocol`, `ScheduleRepositoryProtocol` e `TimesheetRepositoryProtocol` permitem substituir rede e persistência por mocks nos testes. A composição das dependências concretas acontece num único ponto (`AppContainer`).
- **Offline-first (remote-first com fallback)** — os repositórios tentam sempre a rede; em sucesso substituem a cache SwiftData; em falha devolvem a cache. Sem rede e sem cache, é lançado o erro tipado `offlineWithoutCache`, apresentado com mensagem clara e botão de repetição.
- **Erros tipados** — o enum `AppError` cobre URL inválido, falha de rede, erro de servidor, JSON inesperado, conflito de horário (409), erro de persistência e offline sem cache; cada caso tem mensagem própria para o utilizador.
- **DTOs separados do domínio** — os `Codable` (`ScheduleEntryDTO`, etc.) espelham o JSON e convertem-se em modelos de domínio; dados inválidos (ex.: dia da semana fora de 1–7) são descartados em vez de rebentar a app.
- **Snapshot desnormalizado no SwiftData** — as entidades locais são uma cache de leitura substituída a cada sincronização, pelo que se optou por não usar relações entre entidades (justificação no PDF).
- **Estados explícitos de UI** — `ViewState` (idle/loading/loaded/empty/error) garante tratamento de carregamento, lista vazia e erro em todos os ecrãs orientados a dados.

## Estrutura do projeto

```
CampusHub/
├── CampusHub/               # App iOS
│   ├── App/                 # Entry point, configuração, composição (DI)
│   ├── Domain/              # Modelos, protocolos de repositório, AppError
│   ├── Data/
│   │   ├── Network/         # Endpoint, HTTPClient, DTOs (Codable)
│   │   ├── Persistence/     # Entidades SwiftData, LocalStore
│   │   └── Repositories/    # Offline-first: rede + cache
│   └── Presentation/        # Views SwiftUI + ViewModels (MVVM)
├── CampusHubTests/          # Testes unitários (Swift Testing)
├── backend/                 # API REST (Node.js + Express)
├── docs/                    # Documento de arquitetura (PDF)
└── project.yml              # Definição do projeto (XcodeGen)
```

## Testes automatizados

Cobrem as camadas exigidas no enunciado:

- **Camada de dados** — `ScheduleRepositoryTests` e `TimesheetRepositoryTests` (sucesso remoto + atualização de cache, fallback offline, offline sem cache, conflito 409, descarte de dados inválidos) e `SwiftDataLocalStoreTests` (roundtrip real com contentor em memória).
- **ViewModels** — `ScheduleViewModelTests`, `TimesheetViewModelTests` e `AllocationViewModelTests` (transições de estado, filtros e pesquisa, resumo mensal, validação de formulário, mensagens de erro/sucesso).

## Requisitos opcionais implementados

- Tema claro/escuro (preferência persistida) e tipografia dinâmica (fontes semânticas do sistema);
- Pesquisa e filtro por dia na listagem principal;
- Pull-to-refresh;
- Acessibilidade: `accessibilityElement(children: .combine)` nas células e rótulos nos controlos.

## Limitações e trabalho futuro

- **Autenticação** fora do âmbito: o professor ativo é fixado em `AppConfig.currentProfessorID`;
- Registos de horas criados offline não são colocados em fila para envio posterior (o registo exige ligação);
- Localização multilingue (String Catalogs) e pipeline de CI ficam como evolução futura.

## Divisão de tarefas

Trabalho **individual** — Melissa Kaestner (conceção, backend, app iOS, testes e documentação).
