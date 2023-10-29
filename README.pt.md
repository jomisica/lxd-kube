# lxd-projects-provisioning-kubernetes
Escrito por José Miguel Silva Caldeira <miguel@ncdc.pt>.

## Descrição:

Este projeto é uma coleção de templates e scripts que visam provisionar clusters Kubernetes de forma rápida e eficiente em containers LXC.

Através da criação e/ou configuração de templates, será possível otimizar vários aspetos das configurações do LXD e do Kubernetes.

O projeto já distribui templates e um ficheiro de configuração que os referencia, bem como os scripts utilizados para criar containers e clusters Kubernetes.

Este README explica como criar clusters Kubernetes dentro de containers LXD.

> **Note:** Nota: Estas instruções são para fins de desenvolvimento e não são recomendadas para uso em produção.

> **Note:** Nota: Pode ser uma configuração inicial para produção; no entanto, muitos aspetos de segurança e armazenamento têm de ser tratados para serem usados em produção com segurança.

## Para que serve este projeto

Este projeto é utilizado para configurar um cluster Kubernetes em containers LXC. No entanto, existem pelo menos duas maneiras de utilizá-lo: a nível profissional e não profissional. Dentro desses dois principais grupos, existem muitos subgrupos.

No contexto profissional, os computadores em produção têm uma rede estável, IPs estáticos e não mudam de local regularmente, entre outros requisitos. Eles dependem de outros subsistemas, como armazenamento, infraestrutura de rede, etc.

A nível profissional, são utilizadas bridges de sistema para permitir a comunicação entre as máquinas do cluster e outros subsistemas. Naturalmente, é possível empregar VLANs, túneis e outras medidas de segurança para separar a comunicação entre grupos de projetos, etc.

Já no caso dos desenvolvedores, além dos clusters utilizados por profissionais em suas atividades diárias, eles necessitam de um ambiente com configurações específicas que podem ser implantadas e desmontadas rapidamente para fins de testes. Esses clusters geralmente não são estáveis em termos de infraestrutura, pois costumam ser executados em laptops que são levados para diferentes locais, como escritórios de clientes, residências, cafés, etc.

Este script permite a criação de ambos os tipos de cenários: um para uso estável, com base em uma infraestrutura de rede confiável, e outro para desenvolvedores que precisam de flexibilidade durante o processo de desenvolvimento. O cluster Kubernetes permanece estável mesmo se o computador de desenvolvimento for reiniciado, pois o Kubernetes requer que os IPs permaneçam os mesmos desde a instalação.

Nesses casos, o LXD não funciona como um cluster, mas utiliza uma bridge com NAT e aproveita o laptop do desenvolvedor como gateway para a Internet. Os endereços atribuídos aos containers no cluster seguem um padrão, com a única variação sendo o IP ou a rede à qual o computador está fisicamente conectado. A principal preocupação é escolher uma rede que não esteja em uso nos locais frequentados, para garantir que funcione perfeitamente em todos os lugares.

## A árvore de ficheiros envolvido em projecto

Vou explicar como funciona a execução do script e a relação que tem com os templates e os scripts de bootstrap.

Esta é a arvore de ficheiros que está envolvida neste projecto de exemplo que vem acompanhado com o projecto.


```shell
├── config
│   └── test-local.csv
├── kubernetes
│   ├── bootstrap
│   │   ├── default
│   │   │   └── bootstrap.sh
│   │   └── project
│   │       ├── project-kmaster
│   │       │   └── bootstrap.sh
│   │       ├── project-kworker1
│   │       │   └── bootstrap.sh
│   │       └── project-kworker2
│   │           └── bootstrap.sh
│   └── templates
│       ├── default
│       │   ├── kubeadm-config.yaml
│       │   ├── kubeadm-flannel.yaml
│       │   ├── kubeadm-init-config.yaml
│       │   └── kubeadm-join-config.yaml
│       └── project
│           └── kubeadm-init-config.yaml
├── lxc
    ├── lxdbridge
    │   └── test
    │       └── bridge.yaml
    ├── profiles
        ├── default
        │   └── k8s.yaml
        └── test
            ├── k8s-kmaster.yaml
            ├── k8s-kworker1.yaml
            └── k8s-kworker2.yaml
```

Vou explicar como funciona a execução do script e a relação que tem com os templates e os scripts de bootstrap.

Esta é a arvore de ficheiros que está envolvida neste projecto de exemplo que vem acompanhado com o projecto.

Quando se inicia o script com um determinado ficheiro de configuração, que neste caso é test-local.csv. O script começa por uma filtragem removendo linhas vazias e fazendo trim aos dados de cada linha e removendo linhas com um numero de colunas erradas.
Uma verificação minima no ficheiro de configuração.

Depois o script começa a fazer loops sobre as linhas de dados. 

Começa por criar todos os projectos existentes no ficheiro de configuração no LXD, para que dentro destes projectos possam existir containers, perfis, imagens, etc, associadas.

Depois o script detecta se o LXD está a trabalhar em cluster. Se ele não estiver a treabalhar em cluster, ele analisa se o ficheiro lxc/lxdbridge/< corrente projecto >/bridge.yaml existe. Se esse ficheiro existir ele cria uma bridge local em NAT com as configurações presentes neste ficheiro. Se o ficheiro não existir ele não cria qualquer bridge. Quando existe a bridge configurada nos perfis de estar de acordo. Como podem ver pelos ficheiros disponibilizados para este projecto de test. Esta é uma configuração ideal para ter em portateis. 

Depois o script faz um loop novamente criando todos os perfis que estejam listados no ficheiro de configuração e a cada um deles é atribuido o conteudo dos ficheiros neste caminho, lxc/profiles/< nome do projecto >/< nome do perfil >.yaml. Se este ficheiro não existir é usado em sua substituição o perfil por defeito, disponibilizado com o projecto, que se encontra no seguinte directório lxc/profiles/default/k8s.yaml.

Depois entra em loop novamente criando todos os containers necessários para o projecto, e a cada um deles associa o correspondente perfil criado no passo anterior.

Depois é adicionada a chave publica do SSH a cada container, para podermos aceder para analisar algo.

Neste momento está tudo criado no LXD, projectos, perfis, containers.

O script aguarda que todos os containers estejam a correr e com a interface de rede activa com IP, para poder começar a instalar o kubernetes nos containers.

O script faz um loop pelos containers e começa com o primeiro da lista que tem de ser o master plane do kubernetes. Resolve o dominio que é fornecido no ficheiro de configuração, para saber se resolve para o IP que o container ganhou quer via dhcp neste caso ou com outra configuração através do perfil do container no processo de criação. Se o dominio resolver correctamente para o IP do container, a instalação prossegue, caso contrario é abortada a instalação.

Depois é lançado o script de bootstrap que se encontra no seguinte directorio, kubernetes/bootstrap/< nome do projecto >/< nome do container hostname >/bootstrap.sh se existir. Se este ficheiro não existir é usado o script de bootstrap por defeito que se encontra no seguinte directorio, kubernetes/bootstrap/default/bootstrap.sh. 
Este script tem como função instalar as dependencias e o kubernetes, containerd por defeito. No entanto pode ser modificado para fazer algo mais que seja necessário em determinado contexto.

Depois o script gera os ficheiros de configuração para configurar o kubernetes com os dados do ficheiro de configuração bem como token gerado necessário.

Depois são descarregadas as imagens base do kubernetes, que depende claro da versão do cluster que estamos a instalar. Este processo é bem demorado, dependendo da ocasião chega a meia hora.

Depois é inicializado o master plane com o ficheiro gerado nos processos anteriores. Se correr tudo bem o master plane é inicializado.

Depois é feito a instalação do Flannel no kubernetes para que este possa gerir a rede e estar pronto para que os worker nodes possam ser juntos ao cluster.

Basicamente termina a instalação do master plane.

De seguida o script começa a trabalhar nos workers nodes, que é um processo mais simples e rápido.

Depois é lançado o script de bootstrap que se encontra no seguinte directorio, kubernetes/bootstrap/< nome do projecto >/< nome do container hostname >/bootstrap.sh se existir. Se este ficheiro não existir é usado o script de bootstrap por defeito que se encontra no seguinte directorio, kubernetes/bootstrap/default/bootstrap.sh.
Que trata do processo de instalação dos softwares.

Depois com o ficheiro que foi gerado no processo de configuração do master o worker node é junto ao cluster.

Este processo dos workers nodes é o mesmo para todos os workers nodes.

Quando o script termina de adicionar todos os worker nodes, fica concluida a configuração e o script termina.

Se houver algum error durante o processo todo o script é abortado, com alguma mensagem de erro.


## Instalação do LXD no Ubuntu

Pode encontrar mais informações sobre como instalar e configurar o LXD neste link.

```shell
$ sudo snap install lxd
```

## Configuração do LXD

Antes de prosseguir, é necessário criar uma bridge no Linux e especificar a bridge que deseja que o LXD utilize. Criámos uma bridge chamada "lxdbridge" para os exemplos fornecidos.

Se precisar de orientações sobre como criar uma bridge no Linux, pode consultar este artigo sobre o uso do bridge-utils no Ubuntu ou outro recurso da sua escolha.

Para configurar o LXD, aceite as opções padrão, exceto a configuração da bridge. Não aceite a criação da bridge por padrão. O LXD pedir-lhe-á para especificar uma bridge a utilizar, e deverá fornecer o nome da bridge que criou, que é "lxdbridge".

Ter uma bridge externa pode ser útil para atribuir um endereço MAC a cada perfil, garantindo que os containers mantenham um IP consistente. Além disso, como o Kubernetes depende da configuração de domínio, é essencial garantir que o nome de domínio que fornece na lista de nós resolva para o IP de cada nó.

Se o seu servidor DHCP permitir reservas de MAC, crie uma reserva para cada endereço MAC no perfil de cada container. Certifique-se de que não utiliza endereços MAC associados a dispositivos de rede na sua rede.

Se o seu servidor DNS permitir que crie registos, adicione um para cada cluster usando o domínio da sua escolha. Caso contrário, configure o ficheiro hosts para associar cada domínio ao endereço IP de cada instância LXD.

## Chaves SSH

Dentro do diretório lxd/SSH-KEY, encontrará um EXEMPLO de CHAVE PRIVADA e PÚBLICA. A chave pública será distribuída para todos os containers. Esta opção é útil para utilizar com o Ansible ou para acesso SSH direto para fins de teste.

Pode criar um novo par de chaves e colocá-lo no mesmo local com o mesmo nome.

## Ficheiros de Configuração

> **Note:** Eu tive que alterar o formato dos ficheiros de configuração do tipo CSV para YAML. Isto tem de ser logo no inicio, agora, visto que a configuração em ficheiro CSV é possivel no entanto muito limitadora. Como tambem diferente dos ficheiros de configuração quer do LXD quer do kubernetes, que é o YAML que tem maior uso.
O formato do ficheiro como YAML permitirá mais facilmente evoluir este script com mais opções, para que se vá adaptando ao longo do desenvolvimento do LXD e Kubernetes.

### Exemplo de ficheiro de configuração

```yaml
config:
  description: This example project works on clustered LXD.
    But as it uses a NAT network interface, all containers must be in the same
    member of the LXD cluster, otherwise Kubernetes will not be able to
    communicate with the nodes. To do this, I use the target option to specify
    the LXD member that I need to create containers to be used by Kubernetes.
  lxd:
    projectName: ncdc1
    target: terra # cluster members: terra, marte
  kubernetes:
    clusterName: ncdc1
    version: 1.22.0
    podSubnet: 10.10.0.0/16
    controlPlaneEndpointDomain: ncdc.pt
  instances:
  - instance:
    lxd:
      name: ncdc1-kmaster
      image: ubuntu:22.04
      profile: k8s-kmaster
    kubernetes:
      type: master
  - instance:
    lxd:
      name: ncdc1-kworker1
      image: ubuntu:22.04
      profile: k8s-kworker1
    kubernetes:
      type: worker
  - instance:
    lxd:
      name: ncdc1-kworker2
      image: ubuntu:22.04
      profile: k8s-kworker2
    kubernetes:
      type: worker
```


## Perfis LXD

Cada container no cluster é atribuído a um perfil. Isso é necessário para que possamos especificar um endereço MAC estático para cada container e especificar a bridge à qual o container deve pertencer.

Isso também nos dá mais liberdade para atribuir recursos de CPU e RAM a cada container.

A etiqueta "name" deve conter o mesmo nome de ficheiro sem a extensão, o mesmo nome especificado na lista de nodes.

```yaml
config:
  limits.memory: 2GB
  limits.cpu: 1,2
  #limits.cpu: "2"
  #limits.cpu: 0-3
  limits.cpu.allowance: 30%
  limits.cpu.priority: 5
  #limits.cpu.allowance: 50ms/200ms
  limits.memory.swap: "false"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: "lxc.apparmor.profile=unconfined\nlxc.cap.drop= \nlxc.cgroup.devices.allow=a\nlxc.mount.auto=proc:rw sys:rw\nlxc.mount.entry = /dev/kmsg dev/kmsg none defaults,bind,create=file"
  security.privileged: "true"
  security.nesting: "true"
description: LXD profile for Kubernetes
devices:
  eth0:
    name: eth0
    hwaddr: 00:16:3e:10:00:01
    nictype: bridged
    parent: lxdbridge
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: k8s-kmaster
used_by: []
```

## Clonar o projeto

Pode clonar o repositório para a sua localização preferida.

```shell
$ git clone https://github.com/jomisica/lxd-projects-provisioning-kubernetes.git
```

Aceda ao diretório do projeto

```shell
$ cd lxd-projects-provisioning-kubernetes
```

### Criar bridge

Fornecemos um script para configurar a bridge. Mas deve ser usado apenas no Ubuntu >=18.04. Não foi testado em outras versões. Deve também usar este script apenas para criar a bridge se o seu computador tiver apenas uma interface de rede. Para configurá-lo em computadores com mais de uma interface de rede, é possível, mas terá que modificar o template que fornecemos em 'lxc/netplan/netplancfg.yaml'. Também será necessário editar o template se precisar de configurar um IP estático na bridge. Se precisar de ajuda sobre como fazer isso, entre em contato.

> **Note:** Nota: Ao testar numa máquina virtual (por exemplo, virtualbox), é possível, no entanto, a interface de rede nas definições da máquina virtual deve permitir que a interface esteja no modo promíscuo.

A execução do comando a seguir criará a bridge 'lxdbridge' e adicionará a interface no seu sistema que possui a rota padrão à bridge 'lxdbridge'. Esta bridge será configurada com um IP dinâmico, pelo que deverá criar uma reserva com o endereço MAC da bridge no seu servidor DHCP, para que mantenha o mesmo IP.

```shell
$ sudo bash create-lxd-bridge.sh
```

### Instalar e configurar o LXD

Fornecemos um script para instalar e configurar o LXD no Ubuntu 22.04, a única versão que testamos. No entanto, deve apenas instalar com o script se desejar opções simples. Por predefinição, o armazenamento está no modo 'dir', que consumirá o mesmo sistema de ficheiros que outras aplicações. A bridge configura a 'lxdbridge' conforme desejado e deve já estar criada. Não está no modo Cluster.
Para configurações mais avançadas, é necessário configurar o template 'lxc/preseed/preseed.yaml'. Se precisar de ajuda sobre como fazer isso, entre em contato.

```shell
$ sudo bash install-lxd.sh
```

## Como usar o script

O ficheiro 'config/default.csv' é o ficheiro utilizado pelo script para criar os containers e configurar os clusters Kubernetes desejados. Este mesmo ficheiro é utilizado quando desejamos eliminar projetos. É um ficheiro CSV que utiliza uma vírgula como separador. Todas as linhas devem terminar com uma vírgula. Cada linha deve conter nove colunas.

### Provisionar Clusters Kubernetes

Para provisionar os projetos definidos no ficheiro de configuração, execute o seguinte comando:

```shell
$ bash lxd-kube provision --config project-config-file.yaml
```

### Destruir containers LXD e clusters Kubernetes

Para destruir os projetos definidos no ficheiro de configuração, execute o seguinte comando:

```shell
$ bash lxd-kube destroy --config project-config-file.yaml
```

As ações são sempre realizadas em massa; por exemplo, podemos interromper todos os containers do LXD listados no ficheiro de configuração.

Estas ações são importantes se trabalharmos com mais de um projecto ao mesmo tempo. Podemos ter configurados varios clusters, no entanto podemos querer trabalhar em apenas um de cada vez. Pausando ou parando os projectos que não estamos a usar no momento é uma poupança de recursos.

### Parar containers

```shell
$ bash lxd-kube stop --config project-config-file.yaml
```

### Iniciar containers

```shell
$ bash lxd-kube start --config project-config-file.yaml
```

### Pausar containers

```shell
$ bash lxd-kube pause --config project-config-file.yaml
```

### Reinicializar containers

```shell
$ bash lxd-kube restart --config project-config-file.yaml
```

## Sugestões para Melhorias

Se identificar oportunidades de melhoria neste projeto ou encontrar problemas que deseja relatar, a sua contribuição é essencial para tornar o projeto mais robusto e valioso. Encorajamos ativamente a comunidade de utilizadores a envolver-se e colaborar. Eis algumas formas de participar:

- **Reportar Problemas**: Se encontrar quaisquer problemas, bugs ou comportamentos inesperados ao utilizar este projeto, reporte-os na nossa [página de problemas](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Certifique-se de fornecer informações detalhadas para que possamos compreender e resolver o problema.

- **Fazer Sugestões**: Se tiver ideias para melhorar o projeto, adicionar funcionalidades ou otimizar a experiência do utilizador, sinta-se à vontade para partilhá-las na nossa [página de problemas](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Gostaríamos de ouvir as suas sugestões.

- **Contribuir com Código**: Se é um programador e deseja contribuir diretamente para o projeto, considere criar pedidos de pull (PRs).

Lembre-se de que o seu envolvimento é valioso e pode ajudar a tornar este projeto ainda mais útil para a comunidade. Agradecemos por fazer parte deste esforço de código aberto!