# Zsh Config — Fedora Optimized

[![Zsh](https://img.shields.io/badge/Shell-Zsh-f15a24?logo=zsh&logoColor=white)](https://zsh.sourceforge.io/)
[![Fedora](https://img.shields.io/badge/OS-Fedora-294172?logo=fedora&logoColor=white)](https://getfedora.org/)
[![Oh My Zsh](https://img.shields.io/badge/Framework-Oh%20My%20Zsh-000000?logo=github&logoColor=white)](https://ohmyz.sh/)
[![Powerlevel10k](https://img.shields.io/badge/Theme-Powerlevel10k-blue?logo=github&logoColor=white)](https://github.com/romkatv/powerlevel10k)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Configuração do Zsh otimizada para Fedora Linux, com foco em performance, segurança e produtividade. Utiliza Oh My Zsh, Powerlevel10k e um sistema inteligente de cache de plugins.

---

## 🧭 Navegação Rápida

**Documentação:**
- [📚 Documentação Técnica Completa →](docs.md)

**Seções deste documento:**
- [↗️ Recursos Principais](#recursos-principais)
- [↗️ Compatibilidade](#compatibilidade)
- [↗️ Dependências Recomendadas](#dependências-recomendadas)
- [↗️ Instalação](#instalação)
- [↗️ Aliases Disponíveis](#aliases-disponíveis)
  - [Listagem de Arquivos](#listagem-de-arquivos-eza)
  - [Navegação](#navegação)
  - [Limpeza do Sistema](#limpeza-do-sistema-fedora)
  - [Grep Colorido](#grep-colorido)
- [↗️ Funções Disponíveis](#funções-disponíveis)
  - [Navegação e Arquivos](#navegação-e-arquivos)
  - [Git](#git)
  - [Utilitários](#utilitários)
- [↗️ Performance](#performance)
- [↗️ Uso de IA](#uso-de-ia)

---

## Recursos Principais

- **Instant Prompt**: Carregamento imediato do prompt via Powerlevel10k
- **Cache Inteligente de Plugins**: Rebuild automático baseado em fingerprint das ferramentas
- **Boot Timer**: Monitoramento do tempo de inicialização do shell
- **Aliases Produtivos**: Comandos simplificados para navegação e listagem de arquivos
- **Funções Utilitárias**: Ferramentas para Git, arquivos, backup e gerenciamento de sistema
- **Segurança no Histórico**: Filtragem automática de credenciais sensíveis
- **Lazy Loading**: Carregamento diferido de plugins pesados (opcional)

## Compatibilidade

| Sistema | Status |
|---------|--------|
| **Fedora Linux** | ✅ Foco principal |
| Outras distros RPM | ⚠️ Funcional (ajustar gerenciador de pacotes) |
| Debian/Ubuntu | ⚠️ Requer adaptação dos aliases DNF |
| macOS | ⚠️ Parcial (testar compatibilidade) |

## Dependências Recomendadas

```bash
# Essenciais
zsh git

# Ferramentas opcionais (habilitam funcionalidades extras)
eza fzf zoxide

# Framework e tema
oh-my-zsh powerlevel10k

# Gerenciadores de pacote (Fedora)
dnf flatpak
```

### Instalação das Dependências (Fedora)

```bash
sudo dnf install zsh git eza fzf zoxide -y

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Plugins opcionais
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## Instalação

1. Clone ou copie este repositório:
   ```bash
   cp .zshrc ~/.zshrc
   ```

2. Reinicie o shell ou execute:
   ```bash
   source ~/.zshrc
   ```

3. Na primeira execução, o Powerlevel10k iniciará o assistente de configuração.

## Aliases Disponíveis

### Listagem de Arquivos (eza)

| Alias | Comando Equivalente | Descrição |
|-------|---------------------|-----------|
| `ls` | `eza --icons --group-directories-first` | Listagem com ícones, diretórios primeiro |
| `ll` | `eza -lh --icons --group-directories-first --git` | Lista detalhada com status Git |
| `la` | `eza -lah --icons --group-directories-first --git` | Lista todos (inclui ocultos) com Git |
| `l` | `eza -1 --icons` | Um arquivo por linha com ícones |
| `lt` | `eza --tree --icons --level=2` | Visualização em árvore (2 níveis) |

> **Nota:** Requer `eza` instalado. Se não disponível, os aliases não são criados.

### Navegação

| Alias | Ação |
|-------|------|
| `home` | `cd ~` — Vai para a home |
| `docs` | `cd ~/Documents` — Vai para Documentos |
| `up` | `cd ..` — Sobe 1 nível |
| `up2` | `cd ../..` — Sobe 2 níveis |
| `up3` | `cd ../../..` — Sobe 3 níveis |
| `up4` | `cd ../../../..` — Sobe 4 níveis |

### Limpeza do Sistema (Fedora)

| Alias | Ação |
|-------|------|
| `dnf-clean` | Remove dependências órfãs e limpa cache DNF |
| `flatpak-clean` | Remove runtimes Flatpak não utilizados |
| `sys-clean` | Executa ambas limpezas (DNF + Flatpak) |

### Grep Colorido

| Alias | Ação |
|-------|------|
| `grep` | `grep --color=auto` |
| `fgrep` | `fgrep --color=auto` |
| `egrep` | `egrep --color=auto` |

## Funções Disponíveis

### Navegação e Arquivos

#### `dtop`
Navega para `~/Desktop`.
```bash
dtop
```

#### `mkcd <diretório>`
Cria um diretório e entra nele.
```bash
mkcd meu-projeto
# Equivalente a: mkdir -p meu-projeto && cd meu-projeto
```

#### `nf <arquivo>`
Cria um arquivo vazio no diretório atual.
```bash
nf README.md
# Saída: ✅ Arquivo "README.md" criado em /caminho/atual
```

### Git

#### `gcom "mensagem"`
Adiciona todos os arquivos e faz commit.
```bash
gcom "Correção de bug crítico"
```
- Valida se está em repositório Git
- Verifica se há mudanças pendentes
- Retorna erro se working tree estiver limpo

#### `lazyg "mensagem"`
Commit interativo com opção de push.
```bash
lazyg "Nova feature implementada"
```
Fluxo:
1. Executa `gcom` internamente
2. Pergunta: `🚀 Enviar para origin/<branch>? [s/N]`
3. Timeout de 10 segundos
4. Confirmação com `s/S/y/Y` envia o push

### Utilitários

#### `sudo !!`
Reexecuta o último comando com `sudo`, com proteções de segurança.
```bash
# Exemplo de uso
cat /etc/shadow        # Permission denied
sudo !!                # Executa: sudo cat /etc/shadow
```

**Comandos bloqueados por segurança:**
- `sudo` recursivo
- `rm -rf /`
- `mkfs`
- `dd of=`
- `chmod -R 777 /`

#### `sedi "padrão" <arquivo>`
Substituição segura com backup automático.
```bash
sedi "s/old/new/g" config.txt
# Cria backup: config.txt.bak.YYYYMMDDHHMMSS
```

#### `extract <arquivo>`
Extrai arquivos compactados automaticamente.
```bash
extract projeto.tar.gz
extract backup.zip
extract arquivo.rar
```
Formatos suportados: `.tar.bz2`, `.tgz`, `.tar.xz`, `.bz2`, `.gz`, `.tar`, `.zip`, `.rar`, `.7z`

#### `bk <arquivo>`
Cria backup de um arquivo.
```bash
bk config.json
# Saída: ✅ Backup: config.json.bak.20250101_120000
```

#### `port [número]`
Verifica portas em uso.
```bash
port          # Lista todas as portas
port 8080     # Verifica se porta 8080 está em uso
```

#### `zshrc-time`
Exibe tempo de carregamento do `.zshrc`.
```bash
zshrc-time
# Saídas possíveis:
# ⚡ .zshrc: 95ms (excelente)
# ⚡ .zshrc: 180ms (bom)
# ⚡ .zshrc: 350ms (aceitável)
# 🐢 .zshrc: 620ms (lento)
```

## Performance

### Sistema de Cache

O cache de plugins é gerado automaticamente e reconstruído apenas quando:
- O fingerprint das ferramentas monitoradas muda (`zoxide`, `eza`, `fzf`)
- O arquivo de cache não existe

**Benefícios:**
- Evita execução repetida de comandos de inicialização
- Reduz tempo de boot do shell em ~30-50%
- Atualização transparente sem intervenção do usuário

### Boot Timer

O tempo de carregamento é medido e armazenado na variável `_zshrc_load_ms`. Use `zshrc-time` para verificar.

**Classificação de performance:**
- `< 150ms`: Excelente
- `< 200ms`: Bom
- `< 500ms`: Aceitável
- `≥ 500ms`: Lento (considere revisar plugins)

### Compilação Bytecode

O `.zshrc` é compilado automaticamente para `.zshrc.zwc` (bytecode Zsh), acelerando parsing em execuções subsequentes.

---

[← Voltar ao Topo](#zsh-config--fedora-optimized) | [📚 Documentação Técnica →](docs.md)

> **Dica:** Para configurações pessoais específicas, crie `~/.zshrc.local` e ele será carregado automaticamente ao final.

## Uso de IA

Este projeto foi desenvolvido com auxílio de Inteligência Artificial em todas as etapas:
- Geração e refatoração do código
- Revisão técnica e ortográfica da documentação
- Organização estrutural e identificação de padrões
- Sugestões de otimização e boas práticas

A IA atuou como ferramenta de apoio para acelerar o desenvolvimento e melhorar a qualidade do código e da documentação.