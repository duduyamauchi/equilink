import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:equilink_core/equilink_core.dart';
import '../core/tema.dart';
import '../escopo.dart';
import '../rotas.dart';
import '../servicos/compartilhar.dart';
import '../widgets/comuns.dart';
import '../widgets/visualizador_midia.dart';

/// Tela "Detalhes do Cavalo": identificação, mídias, ficha técnica,
/// proprietário, criador e descrição do animal.
class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  int _aba = 0;
  int _paginaCarrossel = 0;
  final _controladorCarrossel = PageController();

  @override
  void dispose() {
    _controladorCarrossel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = RepositorioEscopo.de(context);
    final visualizador = VisualizadorEscopo.de(context);
    // Registro da URL que não existe: explica em vez de mostrar outro animal.
    final erroFoco = repositorio.erroFoco;
    if (erroFoco != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Cavalo')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(Espacos.x5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 38, color: Cores.dourado),
                  const SizedBox(height: Espacos.x4),
                  Text(
                    erroFoco,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Cores.texto,
                    ),
                  ),
                  const SizedBox(height: Espacos.x2),
                  const Text(
                    'Confira o registro na placa ou abra o perfil do destaque do haras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Cores.textoSecundario, height: 1.5),
                  ),
                  const SizedBox(height: Espacos.x4),
                  FilledButton(
                    onPressed: () {
                      repositorio.limparFoco();
                      context.go(Rotas.perfil);
                    },
                    child: const Text('Ver o destaque do haras'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final cavalo = repositorio.cavaloObrigatorio;
    final fotos = cavalo.fotos;
    final videos = cavalo.videos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Cavalo'),
        leading: IconButton(
          tooltip: 'Placa de identificação',
          icon: const Icon(Icons.qr_code_2, size: 24),
          onPressed: () => context.push(Rotas.placa),
        ),
        actions: [
          IconButton(
            tooltip: 'Compartilhar perfil',
            icon: const Icon(Icons.ios_share),
            onPressed: () =>
                CompartilhamentoPerfil.compartilhar(context, repositorio),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Espacos.x6),
        children: [
          _Carrossel(
            fotos: fotos,
            controlador: _controladorCarrossel,
            pagina: _paginaCarrossel,
            aoMudarPagina: (p) => setState(() => _paginaCarrossel = p),
            aoAbrirFoto: (indice) {
              repositorio.analytics.registrar(
                'midia_visualizada',
                entidade: 'midia',
                entidadeId: fotos[indice].id,
                propriedades: {'tipo': 'foto', 'origem': 'carrossel'},
              );
              visualizador.abrir(fotos[indice]);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Espacos.x4,
              Espacos.x4,
              Espacos.x4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Raios.pequeno),
                      child: ImagemMidia(
                        cavalo.fotoPerfil,
                        largura: 64,
                        altura: 64,
                        ajuste: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Espacos.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cavalo.nome,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.15,
                              color: Cores.texto,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${cavalo.registro}  |  ${cavalo.sexo.rotulo}  |  '
                            '${dataCurta(cavalo.nascimento)}  |  ${cavalo.pelagem}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Cores.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Etiqueta(
                                '${cavalo.vitorias} vitórias',
                                cor: Cores.verde,
                                fundo: Cores.verdeFundo,
                                icone: Icons.emoji_events,
                                compacta: true,
                              ),
                              Etiqueta(
                                'Registro ABQM',
                                cor: Cores.dourado,
                                fundo: Cores.dourado.withValues(alpha: 0.14),
                                icone: Icons.verified,
                                compacta: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.x4),
                AbasPilula(
                  abas: const ['Fotos', 'Vídeos', 'Genealogia', 'Histórico'],
                  contagens: [fotos.length, videos.length, null, null],
                  selecionada: _aba,
                  aoSelecionar: (i) {
                    repositorio.analytics.registrar(
                      'aba_alterada',
                      propriedades: {
                        'tela': '/perfil',
                        'aba': const ['Fotos', 'Vídeos', 'Genealogia', 'Histórico'][i],
                      },
                    );
                    setState(() => _aba = i);
                  },
                ),
                const SizedBox(height: Espacos.x4),
                switch (_aba) {
                  0 => _GradeFotos(fotos: fotos, aoAbrir: visualizador.abrir),
                  1 => _ListaVideos(
                    videos: videos,
                    aoAbrir: visualizador.abrir,
                  ),
                  2 => _ResumoGenealogia(cavalo: cavalo),
                  _ => _ResumoHistorico(cavalo: cavalo),
                },
                const SizedBox(height: Espacos.x5),
                Painel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TituloSecao('Proprietário'),
                      const SizedBox(height: Espacos.x3),
                      _LinhaContato(
                        icone: Icons.person_outline,
                        rotulo: 'Nome',
                        valor: cavalo.proprietario.nome,
                      ),
                      _LinhaContato(
                        icone: Icons.home_outlined,
                        rotulo: 'Fazenda',
                        valor: cavalo.proprietario.fazenda,
                      ),
                      _LinhaContato(
                        icone: Icons.phone_outlined,
                        rotulo: 'Telefone',
                        valor: telefone(cavalo.proprietario.telefone),
                      ),
                      _LinhaContato(
                        icone: Icons.location_on_outlined,
                        rotulo: 'Localização',
                        valor: cavalo.proprietario.cidade,
                        ultima: true,
                      ),
                      const Divider(height: Espacos.x5),
                      const TituloSecao('Criador'),
                      const SizedBox(height: Espacos.x3),
                      _LinhaContato(
                        icone: Icons.agriculture_outlined,
                        rotulo: 'Haras',
                        valor: cavalo.criador.nome,
                      ),
                      _LinhaContato(
                        icone: Icons.place_outlined,
                        rotulo: 'Cidade',
                        valor: cavalo.criador.cidade,
                        ultima: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacos.x4),
                Painel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TituloSecao('Ficha técnica'),
                      const SizedBox(height: Espacos.x4),
                      Wrap(
                        spacing: Espacos.x4,
                        runSpacing: Espacos.x4,
                        children: [
                          _FichaItem(rotulo: 'Raça', valor: cavalo.raca),
                          _FichaItem(rotulo: 'Sexo', valor: cavalo.sexo.rotulo),
                          _FichaItem(
                            rotulo: 'Nascimento',
                            valor: dataCurta(cavalo.nascimento),
                          ),
                          _FichaItem(
                            rotulo: 'Idade',
                            valor: idade(
                              cavalo.nascimento,
                              referencia: repositorio.hoje,
                            ),
                          ),
                          _FichaItem(rotulo: 'Pelagem', valor: cavalo.pelagem),
                          _FichaItem(rotulo: 'Altura', valor: cavalo.altura),
                          _FichaItem(rotulo: 'Peso', valor: cavalo.peso),
                          _FichaItem(
                            rotulo: 'Registro',
                            valor: 'ABQM ${cavalo.registro}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacos.x4),
                Painel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TituloSecao(
                        'Sobre o animal',
                        acao: TextButton.icon(
                          onPressed: () =>
                              _editarDescricao(context, repositorio),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Editar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Cores.dourado,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Espacos.x2),
                      Text(
                        cavalo.descricao,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Cores.textoSecundario,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacos.x5),
                BotaoDourado(
                  rotulo: 'Compartilhar perfil',
                  icone: Icons.ios_share,
                  aoTocar: () =>
                      CompartilhamentoPerfil.compartilhar(context, repositorio),
                ),
                const SizedBox(height: Espacos.x3),
                BotaoDourado(
                  rotulo: 'Gerar placa de identificação (QR Code)',
                  icone: Icons.qr_code_2,
                  escuro: true,
                  aoTocar: () => context.push(Rotas.placa),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarDescricao(
    BuildContext context,
    Repositorio repositorio,
  ) async {
    final controlador = TextEditingController(
      text: repositorio.cavaloObrigatorio.descricao,
    );
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar descrição'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controlador,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText:
                  'Descreva o temperamento, a linhagem e o desempenho do animal.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controlador.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      await repositorio.atualizarDescricao(repositorio.cavaloObrigatorio.id, resultado);
      repositorio.analytics.funil('conteudo', 'descricao_editada');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descrição atualizada com sucesso.')),
        );
      }
    }
  }
}

class _Carrossel extends StatelessWidget {
  const _Carrossel({
    required this.fotos,
    required this.controlador,
    required this.pagina,
    required this.aoMudarPagina,
    required this.aoAbrirFoto,
  });

  final List<Midia> fotos;
  final PageController controlador;
  final int pagina;
  final ValueChanged<int> aoMudarPagina;
  final ValueChanged<int> aoAbrirFoto;

  @override
  Widget build(BuildContext context) {
    // Sem fotos, o carrossel vazio ocupava 214 px e mostrava "1/0" — o perfil
    // abria com um buraco no topo e um contador sem sentido.
    if (fotos.isEmpty) {
      return Container(
        height: 132,
        color: Cores.trilho,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 26, color: Cores.textoSecundario),
            const SizedBox(height: Espacos.x2),
            Text(
              'Sem fotos cadastradas',
              style: TextStyle(fontSize: 12.5, color: Cores.textoSecundario),
            ),
            const SizedBox(height: Espacos.x1),
            Text(
              'Use a foto de perfil abaixo para identificar o animal.',
              style: TextStyle(fontSize: 11, color: Cores.textoSecundario),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 214,
      child: Stack(
        children: [
          PageView.builder(
            controller: controlador,
            itemCount: fotos.length,
            onPageChanged: aoMudarPagina,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => aoAbrirFoto(i),
              child: ImagemMidia(fotos[i].arquivo, ajuste: BoxFit.cover),
            ),
          ),
          Positioned(
            top: Espacos.x3,
            right: Espacos.x3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(Raios.total),
              ),
              child: Text(
                '${pagina + 1}/${fotos.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: Espacos.x3,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < fotos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: i == pagina ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == pagina ? Cores.douradoClaro : Colors.white70,
                      borderRadius: BorderRadius.circular(Raios.total),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeFotos extends StatelessWidget {
  const _GradeFotos({required this.fotos, required this.aoAbrir});

  final List<Midia> fotos;
  final ValueChanged<Midia> aoAbrir;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Espacos.x2,
        crossAxisSpacing: Espacos.x2,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(Raios.pequeno),
        child: GestureDetector(
          onTap: () => aoAbrir(fotos[i]),
          child: ImagemMidia(fotos[i].arquivo, ajuste: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ListaVideos extends StatelessWidget {
  const _ListaVideos({required this.videos, required this.aoAbrir});

  final List<Midia> videos;
  final ValueChanged<Midia> aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x2),
            child: GestureDetector(
              onTap: () => aoAbrir(video),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Raios.medio),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ImagemMidia(
                        video.poster ?? MidiaPadrao.capaVideo,
                        ajuste: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                    Positioned.fill(
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: Espacos.x2,
                      bottom: Espacos.x2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(Raios.total),
                        ),
                        child: Text(
                          duracaoVideo(video.duracaoSegundos ?? 0),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: Espacos.x3,
                      bottom: Espacos.x3,
                      child: Text(
                        video.legenda,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumoGenealogia extends StatelessWidget {
  const _ResumoGenealogia({required this.cavalo});

  final Cavalo cavalo;

  @override
  Widget build(BuildContext context) {
    return Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSecao('Ascendentes diretos'),
          const SizedBox(height: Espacos.x3),
          _LinhaParentesco(papel: 'Pai', ancestral: cavalo.pai),
          const Divider(height: Espacos.x4),
          _LinhaParentesco(papel: 'Mãe', ancestral: cavalo.mae),
          const SizedBox(height: Espacos.x4),
          BotaoDourado(
            rotulo: 'Ver árvore genealógica',
            icone: Icons.account_tree_outlined,
            escuro: true,
            aoTocar: () => context.go(Rotas.genealogia),
          ),
        ],
      ),
    );
  }
}

class _ResumoHistorico extends StatelessWidget {
  const _ResumoHistorico({required this.cavalo});

  final Cavalo cavalo;

  @override
  Widget build(BuildContext context) {
    final provas = cavalo.provasRecentes.take(3).toList();
    return Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSecao('Últimas provas'),
          const SizedBox(height: Espacos.x3),
          for (final prova in provas)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.x3),
              child: Row(
                children: [
                  SeloIniciais(
                    colocacao(prova.colocacao),
                    tamanho: 40,
                    cor: prova.vitoria
                        ? Cores.verdeFundo
                        : Cores.dourado.withValues(alpha: 0.16),
                  ),
                  const SizedBox(width: Espacos.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${prova.nome}  |  ${prova.categoria}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${dataCurta(prova.data)} • ${prova.local}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Cores.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tempoProvaCompacto(prova.tempoSegundos),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Cores.dourado,
                    ),
                  ),
                ],
              ),
            ),
          BotaoDourado(
            rotulo: 'Ver histórico completo',
            icone: Icons.emoji_events_outlined,
            escuro: true,
            aoTocar: () => context.go(Rotas.historico),
          ),
        ],
      ),
    );
  }
}

class _LinhaParentesco extends StatelessWidget {
  const _LinhaParentesco({required this.papel, required this.ancestral});

  final String papel;
  final Ancestral ancestral;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SeloIniciais(
          ancestral.nome
              .split(' ')
              .where((p) => p.length > 2)
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase(),
          tamanho: 40,
        ),
        const SizedBox(width: Espacos.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                papel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Cores.textoSecundario,
                ),
              ),
              Text(
                ancestral.nome,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'ABQM ${ancestral.registro.replaceAll(RegExp(r'^(ABQM|AQHA) '), '')}'
                '${ancestral.pelagem != null ? ' • ${ancestral.pelagem}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Cores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaContato extends StatelessWidget {
  const _LinhaContato({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.ultima = false,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : Espacos.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 17, color: Cores.dourado),
          const SizedBox(width: Espacos.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Cores.textoSecundario,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FichaItem extends StatelessWidget {
  const _FichaItem({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: CampoInfo(rotulo: rotulo, valor: valor),
    );
  }
}
