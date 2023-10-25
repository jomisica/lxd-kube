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

Nesses casos, o LXD não funciona como um cluster, mas utiliza uma bridge com NAT e aproveita o laptop do desenvolvedor como gateway para a Internet. Os endereços atribuídos aos contêineres no cluster seguem um padrão, com a única variação sendo o IP ou a rede à qual o computador está fisicamente conectado. A principal preocupação é escolher uma rede que não esteja em uso nos locais frequentados, para garantir que funcione perfeitamente em todos os lugares.


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

Os ficheiros que descrevem os containers e os nós do Kubernetes são armazenados no diretório 'config' do projeto. Dentro deste diretório, existe um ficheiro chamado 'default.csv.' Este ficheiro é utilizado pelo script como uma lista de containers LXC e nós do Kubernetes que podem ser criados ou destruídos.

No entanto, a ideia por trás deste projeto é possibilitar a configuração de vários projetos e facilitar a criação ou destruição dos projetos ou listas de projetos específicos, conforme necessário.

Para isso, o script permite especificar, através de um parâmetro, qual ficheiro utilizar. Esses ficheiros devem estar localizados na pasta 'config.' É neste local que criamos os ficheiros que contêm as listas de containers LXD e nós do Kubernetes que precisamos. Podemos criar quantos ficheiros forem necessários para os nossos projetos. [Ver como usar](#verificar-o-ficheiro-de-configuração)

Esses ficheiros utilizam o formato CSV e empregam a vírgula como separador. Todas as linhas devem terminar com uma vírgula, e cada linha deve conter nove colunas.

A tabela abaixo apresenta um exemplo de um ficheiro contendo nove containers LXD, organizados em três clusters do Kubernetes, com três containers em cada cluster do Kubernetes.

| LXD_PROJECT    | LXD_PROFILE     | LXD_CONTAINER_NAME/HOSTNAME | LXC_CONTAINER_IMAGE | K8S_TYPE | K8S_API_ENDPOINT_DOMAIN            | K8S_CLUSTER_NAME | K8S_POD_SUBNET | K8S_VERSION |
| --------------- | --------------- | ---------------------------- | ------------------- | -------- | ---------------------------- | ---------------- | -------------- | ----------- |
| project         | k8s-kmaster     | project-kmaster              | ubuntu:22.04        | master   | project.pt     | project          | 10.10.0.0/16  | 1.28.2      |
| project         | k8s-kworker1    | project-kworker1             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project         | k8s-kworker2    | project-kworker2             | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kmaster | project-dev-kmaster          | ubuntu:22.04        | master   | project.pt   | project-dev      | 10.11.0.0/16  | 1.28.2      |
| project-dev     | k8s-dev-kworker1| project-dev-kworker1         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-dev     | k8s-dev-kworker2| project-dev-kworker2         | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kmaster| project-test-kmaster         | ubuntu:22.04        | master   | project.pt  | project-test     | 10.12.0.0/16  | 1.28.2      |
| project-test    | k8s-test-kworker1| project-test-kworker1       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |
| project-test    | k8s-test-kworker2| project-test-kworker2       | ubuntu:22.04        | worker   |                            |                  |              | 1.28.2      |

As colunas que começam com LXD_ contêm dados para configurar os containers, sendo as quatro primeiras colunas.

As colunas que começam com K8S_ contêm dados de configuração do Kubernetes, abrangendo as restantes colunas.

### A coluna LXD_PROJECT

No LXD, temos a flexibilidade de criar projetos, semelhantes aos namespaces do Kubernetes, que ajudam a segregar containers ou máquinas virtuais com base no contexto. Isso permite uma melhor gestão de cada cluster Kubernetes, garantindo que todos os containers dentro de um cluster residam no mesmo projeto LXD.

Esta coluna define o nome do projeto, que deve ser único para cada projeto.

### A coluna LXD_PROFILE

O LXD permite a criação de perfis, que podem ser usados para definir vários aspetos, incluindo opções de rede, armazenamento, permissões e muito mais. Pode atribuir um perfil a um container específico, e quaisquer definições não especificadas no perfil personalizado serão predefinidas nas definições do perfil padrão. Isso permite criar perfis apenas com as opções que diferem das do perfil padrão.

Esta coluna especifica o nome do ficheiro de perfil (sem a extensão) localizado no diretório 'lxc/profiles'. Cada container no cluster deve utilizar um perfil diferente.

### A coluna LXD_CONTAINER_NAME/HOSTNAME

No LXD, os containers devem ter nomes únicos, mesmo que partilhem o mesmo nome em diferentes projetos. Isso ocorre porque HOSTNAME é o nome do container e ter vários containers com o mesmo nome causará conflitos de rede.

Esta coluna define o nome ou o HOSTNAME para cada container.

### A coluna LXC_CONTAINER_IMAGE

Embora o LXD suporte várias imagens de sistema para diferentes fins, o script fornecido aqui funciona com o sistema de pacotes APT e foi testado com imagens de ubuntu:18.04, ubuntu:20.04 e ubuntu:22.04.

Esta coluna especifica o nome e a versão da imagem para cada container.

### A coluna K8S_TYPE

Esta coluna é utilizada pelo script para determinar se deve configurar o Kubernetes como um nó master ou como um nó worker.

Esta coluna pode ter dois valores: "master" ou "worker".

### A coluna K8S_API_ENDPOINT_DOMAIN

Esta coluna define o domínio a utilizar com o master plane. O domínio deve seguir o formato dominio.xyz.
De srá transformado para hostname.dominio.xyz onde o hostname corresponde ao nome especificado na coluna LXD_CONTAINER_NAME/HOSTNAME.

Este domínio é utilizado para aceder à API do Kubernetes através de um nome de domínio em vez de um endereço IP. O script gerará configurações do kubectl para cada cluster utilizando o domínio fornecido nesta coluna.

Internamente, o Kubernetes depende deste domínio nos seus certificados de cluster.

O domínio não precisa necessariamente ser um domínio real acessível publicamente, mas ao resolver o domínio para um endereço IP, ele deve apontar para o IP do container que serve como master plane node. No entanto, pode ser um domínio real adequado para uso na Internet.

### A coluna K8S_CLUSTER_NAME

Dado que pode ter vários clusters, cada cluster Kubernetes deve ter um nome exclusivo. Por exemplo, pode ter um cluster de produção principal, outro para desenvolvimento de aplicações e ainda outro para testar aplicações ou atualizações de configuração. Diferencie esses clusters fornecendo nomes distintos nesta coluna.

Esta coluna especifica o nome de cada cluster Kubernetes.

### A coluna K8S_POD_SUBNET

No Kubernetes, a comunicação entre pods e nodes depende de endereços IP. Para evitar conflitos de endereços IP nos seus clusters, cada cluster deve utilizar uma rede diferente para a sua rede de pods.

Esta coluna especifica a rede a ser utilizada no cluster. Apenas precisa de ser especificada nos nodes de master plane.

### A coluna K8S_VERSION

O Kubernetes oferece várias versões para a implantação de clusters. O script utiliza a versão mais recente definida no ficheiro de configuração. No entanto, tem a flexibilidade de utilizar versões mais antigas a partir de pelo menos a versão 1.22.0. Este script foi testado com versões tão antigas como 1.22.0 e poderá suportar versões ainda mais antigas.

Esta coluna especifica a versão do Kubernetes a ser utilizada, garantindo consistência em todos os nodes dentro de cada cluster. No entanto, tem a opção de configurar clusters com versões diferentes.

## Perfis LXD

Cada container no cluster é atribuído a um perfil. Isso é necessário para que possamos especificar um endereço MAC estático para cada container e especificar a bridge à qual o container deve pertencer.

Isso também nos dá mais liberdade para atribuir recursos de CPU e RAM a cada container.

A etiqueta "name" deve conter o mesmo nome de ficheiro sem a extensão, o mesmo nome especificado na lista de nodes.

```yaml
config:
  limits.cpu: "4"
  limits.memory: 4GB
  limits.memory.swap: "false"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: "lxc.apparmor.profile=unconfined\nlxc.cap.drop= \nlxc.cgroup.devices.allow=a\nlxc.mount.auto=proc:rw sys:rw\nlxc.mount.entry = /dev/kmsg dev/kmsg none defaults,bind,create=file"
  security.privileged: "true"
  security.nesting: "true"
description: Perfil LXD para Kubernetes
devices:
  eth0:
    hwaddr: 00:16:3e:00:c0:88
    name: eth0
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

### Verificar o Ficheiro de Configuração

Este comando irá ler o ficheiro de configuração e filtar apenas as linhas que não aparetem ter erro, deve verificar se não foram excluidas linhas. Se foram é porque está algo mal escrito no ficheiro.

Verificar o ficheiro configuração por defeito.
```shell
$ bash lxd-kube verifyconfig
```

Verificar um ficheiro configuração diferente.
```shell
$ bash lxd-kube verifyconfig --config k8s-1.22.0.csv
```

### Provisionar Clusters Kubernetes

Para provisionar os projetos definidos no ficheiro de configuração 'cluster-config-data.csv', execute o seguinte comando:

Usando o ficheiro configuração por defeito.
```shell
$ bash lxd-kube provision
```

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube provision --config k8s-1.22.0.csv
```

### Destruir containers LXD e clusters Kubernetes

Para destruir os projetos definidos no ficheiro de configuração 'cluster-config-data.csv', execute o seguinte comando:

Usando o ficheiro configuração por defeito.
```shell
$ bash lxd-kube destroyprojects
```

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube destroyprojects --config k8s-1.22.0.csv
```


As ações são sempre realizadas em massa; por exemplo, podemos interromper todos os containers do LXD listados no ficheiro de configuração. Sempre devemos separar os projetos em diferentes ficheiros de configuração. No entanto, se um arquivo contiver mais de um projeto, as ações serão aplicadas a todos os containers listados no ficheiro.

These actions become particularly important when working on multiple projects simultaneously. You might have several clusters configured, but you may only wish to work on one at a time. Pausing or stopping projects that are not in use at a given moment helps conserve resources.

### Parar containers

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube stop --config k8s-1.22.0.csv
```

### Iniciar containers

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube start --config k8s-1.22.0.csv
```

### Pausar containers

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube pause --config k8s-1.22.0.csv
```

### Reinicializar containers

Usando o ficheiro configuração diferente.
```shell
$ bash lxd-kube restart --config k8s-1.22.0.csv
```




## Sugestões para Melhorias

Se identificar oportunidades de melhoria neste projeto ou encontrar problemas que deseja relatar, a sua contribuição é essencial para tornar o projeto mais robusto e valioso. Encorajamos ativamente a comunidade de utilizadores a envolver-se e colaborar. Eis algumas formas de participar:

- **Reportar Problemas**: Se encontrar quaisquer problemas, bugs ou comportamentos inesperados ao utilizar este projeto, reporte-os na nossa [página de problemas](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Certifique-se de fornecer informações detalhadas para que possamos compreender e resolver o problema.

- **Fazer Sugestões**: Se tiver ideias para melhorar o projeto, adicionar funcionalidades ou otimizar a experiência do utilizador, sinta-se à vontade para partilhá-las na nossa [página de problemas](https://github.com/jomisica/lxd-projects-provisioning-kubernetes/issues). Gostaríamos de ouvir as suas sugestões.

- **Contribuir com Código**: Se é um programador e deseja contribuir diretamente para o projeto, considere criar pedidos de pull (PRs).

Lembre-se de que o seu envolvimento é valioso e pode ajudar a tornar este projeto ainda mais útil para a comunidade. Agradecemos por fazer parte deste esforço de código aberto!