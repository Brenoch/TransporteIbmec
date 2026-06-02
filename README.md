# TransporteIBMEC — gerador de Xcode project

Este repositório contém o código-fonte da app SwiftUI. Para gerar o `.xcodeproj` no Mac (compatível com Xcode 13.2), siga os passos abaixo:

1. Instale o XcodeGen:

```bash
brew install xcodegen
```

2. Gere o projeto:

```bash
xcodegen generate
```

3. Abra no Xcode:

```bash
open TransporteIBMEC.xcodeproj
```

Observações:
- O `project.yml` foi configurado com `deploymentTarget: 13.2`.
- Ajuste `bundleId` em `project.yml` se necessário.
