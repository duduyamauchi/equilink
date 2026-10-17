/// Dados de demonstração do haras, em português do Brasil.
///
/// Os registros seguem o padrão visual do aplicativo de referência:
/// cavalo principal ISABEL TORO LEO (registro P341234) e as baias 01 a 05.
library;

import 'modelos.dart';

const caminhoImagens = 'assets/img';
const caminhoVideos = 'assets/video';

DateTime _d(int dia, int mes, int ano) => DateTime(ano, mes, dia);

// ---------------------------------------------------------------------------
// Genealogia
// ---------------------------------------------------------------------------

const _bisavo1 = Ancestral(
  nome: 'Doc Bar',
  registro: 'ABQM 102.334',
  pelagem: 'Alazã',
);

const _bisavo2 = Ancestral(
  nome: 'Miss Holly Bee',
  registro: 'AQHA 445.210',
  pelagem: 'Castanha',
);

const _bisavo3 = Ancestral(
  nome: 'Peppy San Badger',
  registro: 'AQHA 1974.512',
  pelagem: 'Alazã',
);

const _bisavo4 = Ancestral(
  nome: 'Sugar Badger',
  registro: 'AQHA 512.887',
  pelagem: 'Castanha',
);

const _bisavo5 = Ancestral(
  nome: 'Grey Badger II',
  registro: 'AQHA 221.905',
  pelagem: 'Tordilha',
);

const _bisavo6 = Ancestral(
  nome: 'Freckles Lady',
  registro: 'AQHA 338.441',
  pelagem: 'Castanha',
);

const _bisavo7 = Ancestral(
  nome: 'Freckles Bandit',
  registro: 'AQHA 188.220',
  pelagem: 'Alazã',
);

const _bisavo8 = Ancestral(
  nome: 'Bandit Joy',
  registro: 'AQHA 402.118',
  pelagem: 'Baia',
);

const _avo1 = Ancestral(
  nome: 'Toro Leo',
  registro: 'ABQM 210.998',
  pelagem: 'Castanha',
  pai: _bisavo1,
  mae: _bisavo2,
);

const _avo2 = Ancestral(
  nome: 'Freckles Sugar',
  registro: 'ABQM 233.104',
  pelagem: 'Alazã',
  pai: _bisavo3,
  mae: _bisavo4,
);

const _avo3 = Ancestral(
  nome: 'Badger Star',
  registro: 'ABQM 265.447',
  pelagem: 'Tordilha',
  pai: _bisavo5,
  mae: _bisavo6,
);

const _avo4 = Ancestral(
  nome: 'Crystal Bandit',
  registro: 'ABQM 277.913',
  pelagem: 'Castanha',
  pai: _bisavo7,
  mae: _bisavo8,
);

const paiDoCavalo = Ancestral(
  nome: 'LEO DO VALE',
  registro: 'ABQM 341.880',
  pelagem: 'Castanha',
  pai: _avo1,
  mae: _avo2,
);

const maeDoCavalo = Ancestral(
  nome: 'FLOR DA SERRA',
  registro: 'ABQM 322.715',
  pelagem: 'Alazã',
  pai: _avo3,
  mae: _avo4,
);

// ---------------------------------------------------------------------------
// Histórico esportivo
// ---------------------------------------------------------------------------

final _provas = <Prova>[
  Prova(
    id: 'p1',
    data: DateTime(2026, 9, 28),
    nome: 'Três Tambores',
    local: 'Barretos - SP',
    categoria: 'Aberta',
    colocacao: 1,
    tempoSegundos: 16.742,
    inscritos: 38,
    premiacao: 'R\$ 4.200,00',
  ),
  Prova(
    id: 'p2',
    data: DateTime(2026, 9, 14),
    nome: 'Maneabilidade',
    local: 'Araçatuba - SP',
    categoria: 'Aberta',
    colocacao: 3,
    tempoSegundos: 17.108,
    inscritos: 25,
    premiacao: 'R\$ 1.100,00',
  ),
  Prova(
    id: 'p3',
    data: DateTime(2026, 8, 30),
    nome: 'Três Tambores',
    local: 'Ribeirão Preto - SP',
    categoria: 'Aberta',
    colocacao: 2,
    tempoSegundos: 16.905,
    inscritos: 41,
    premiacao: 'R\$ 2.300,00',
  ),
  Prova(
    id: 'p4',
    data: DateTime(2026, 8, 9),
    nome: 'Seis Balizas',
    local: 'Porto Feliz - SP',
    categoria: 'Amador',
    colocacao: 1,
    tempoSegundos: 16.583,
    inscritos: 22,
    premiacao: 'R\$ 3.600,00',
  ),
  Prova(
    id: 'p5',
    data: DateTime(2026, 7, 19),
    nome: 'Ranch Sorting',
    local: 'Piracicaba - SP',
    categoria: 'Aberta',
    colocacao: 5,
    tempoSegundos: 18.240,
    inscritos: 30,
  ),
  Prova(
    id: 'p6',
    data: DateTime(2026, 6, 28),
    nome: 'Três Tambores',
    local: 'São José do Rio Preto - SP',
    categoria: 'Aberta',
    colocacao: 4,
    tempoSegundos: 17.402,
    inscritos: 36,
  ),
  Prova(
    id: 'p7',
    data: DateTime(2026, 6, 7),
    nome: 'Maneabilidade',
    local: 'Campinas - SP',
    categoria: 'Amador',
    colocacao: 1,
    tempoSegundos: 16.980,
    inscritos: 19,
    premiacao: 'R\$ 2.800,00',
  ),
  Prova(
    id: 'p8',
    data: DateTime(2026, 5, 17),
    nome: 'Seis Balizas',
    local: 'Indaiatuba - SP',
    categoria: 'Aberta',
    colocacao: 2,
    tempoSegundos: 16.874,
    inscritos: 27,
    premiacao: 'R\$ 1.900,00',
  ),
  Prova(
    id: 'p9',
    data: DateTime(2026, 4, 26),
    nome: 'Três Tambores',
    local: 'Sorocaba - SP',
    categoria: 'Aberta',
    colocacao: 1,
    tempoSegundos: 17.010,
    inscritos: 33,
    premiacao: 'R\$ 3.100,00',
  ),
  Prova(
    id: 'p10',
    data: DateTime(2026, 3, 22),
    nome: 'Ranch Sorting',
    local: 'Bauru - SP',
    categoria: 'Amador',
    colocacao: 6,
    tempoSegundos: 18.610,
    inscritos: 18,
  ),
  Prova(
    id: 'p11',
    data: DateTime(2026, 2, 15),
    nome: 'Três Tambores',
    local: 'Lins - SP',
    categoria: 'Aberta',
    colocacao: 2,
    tempoSegundos: 17.245,
    inscritos: 29,
    premiacao: 'R\$ 1.450,00',
  ),
  Prova(
    id: 'p12',
    data: DateTime(2026, 1, 25),
    nome: 'Maneabilidade',
    local: 'Presidente Prudente - SP',
    categoria: 'Aberta',
    colocacao: 1,
    tempoSegundos: 17.088,
    inscritos: 24,
    premiacao: 'R\$ 2.600,00',
  ),
];

// ---------------------------------------------------------------------------
// Fotos e vídeos
// ---------------------------------------------------------------------------

const _midias = <Midia>[
  Midia(
    id: 'm1',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/hero.jpg',
    legenda: 'Retrato oficial do plantel',
    local: 'Haras Santa Helena',
  ),
  Midia(
    id: 'm2',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p2.jpg',
    legenda: 'Trote de apresentação',
    local: 'Pista coberta',
  ),
  Midia(
    id: 'm3',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p3.jpg',
    legenda: 'Detalhe da cabeça',
    local: 'Haras Santa Helena',
  ),
  Midia(
    id: 'm4',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p4.jpg',
    legenda: 'Alerta no pasto',
    local: 'Piquete 03',
  ),
  Midia(
    id: 'm5',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p5.jpg',
    legenda: 'Perfil de garupa',
    local: 'Haras Santa Helena',
  ),
  Midia(
    id: 'm6',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p6.jpg',
    legenda: 'Treino de rédea',
    local: 'Pista de areia',
  ),
  Midia(
    id: 'm7',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p7.jpg',
    legenda: 'Piquete da manhã',
    local: 'Piquete 01',
  ),
  Midia(
    id: 'm8',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p8.jpg',
    legenda: 'Égua com potro',
    local: 'Maternidade',
  ),
  Midia(
    id: 'm9',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p9.jpg',
    legenda: 'Vista aérea do piquete',
    local: 'Piquete 02',
  ),
  Midia(
    id: 'm10',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p10.jpg',
    legenda: 'Potro curioso',
    local: 'Maternidade',
  ),
  Midia(
    id: 'm11',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p11.jpg',
    legenda: 'Potro no pasto',
    local: 'Piquete 04',
  ),
  Midia(
    id: 'm12',
    tipo: TipoMidia.foto,
    arquivo: '$caminhoImagens/p12.jpg',
    legenda: 'Revoada no pasto',
    local: 'Piquete 05',
  ),
  Midia(
    id: 'v1',
    tipo: TipoMidia.video,
    arquivo: '$caminhoVideos/treino_tambor.mp4',
    poster: '$caminhoImagens/act1.jpg',
    legenda: 'Treino de três tambores',
    duracaoSegundos: 10,
    local: 'Pista de areia',
  ),
  Midia(
    id: 'v2',
    tipo: TipoMidia.video,
    arquivo: '$caminhoVideos/passeio_haras.mp4',
    poster: '$caminhoImagens/p6.jpg',
    legenda: 'Passeio pelas instalações',
    duracaoSegundos: 8,
    local: 'Haras Santa Helena',
  ),
  Midia(
    id: 'v3',
    tipo: TipoMidia.video,
    arquivo: '$caminhoVideos/banho_manejo.mp4',
    poster: '$caminhoImagens/act3.jpg',
    legenda: 'Manejo e banho',
    duracaoSegundos: 7,
    local: 'Tronco de contenção',
  ),
];

// ---------------------------------------------------------------------------
// Manejo, ocorrências e observações
// ---------------------------------------------------------------------------

List<TarefaManejo> _manejoPadrao({bool concluido = true}) => [
  TarefaManejo(
    id: 'rm1',
    tipo: TipoManejo.alimentacao,
    descricao: 'Ração da manhã',
    horario: '06:00',
    quantidade: '1,5 kg',
    concluida: concluido,
    responsavel: 'Carlos',
  ),
  TarefaManejo(
    id: 'rm2',
    tipo: TipoManejo.alimentacao,
    descricao: 'Feno',
    horario: '08:00',
    quantidade: '2,0 kg',
    concluida: concluido,
    responsavel: 'Carlos',
  ),
  TarefaManejo(
    id: 'rm3',
    tipo: TipoManejo.alimentacao,
    descricao: 'Ração da tarde',
    horario: '12:00',
    quantidade: '1,5 kg',
    concluida: concluido,
    responsavel: 'Marina',
  ),
  TarefaManejo(
    id: 'rm4',
    tipo: TipoManejo.agua,
    descricao: 'Troca da água',
    horario: '14:00',
    quantidade: '40 L',
    concluida: concluido,
    responsavel: 'Marina',
  ),
  TarefaManejo(
    id: 'rm5',
    tipo: TipoManejo.exercicio,
    descricao: 'Exercício na guia',
    horario: '15:30',
    quantidade: '30 min',
    concluida: concluido,
    responsavel: 'João',
  ),
  TarefaManejo(
    id: 'rm6',
    tipo: TipoManejo.higiene,
    descricao: 'Limpeza da baia',
    horario: '17:00',
    quantidade: '1 un.',
    concluida: concluido,
    responsavel: 'Carlos',
  ),
  TarefaManejo(
    id: 'rm7',
    tipo: TipoManejo.alimentacao,
    descricao: 'Ração da noite',
    horario: '18:00',
    quantidade: '1,5 kg',
    concluida: false,
    responsavel: 'Marina',
  ),
  TarefaManejo(
    id: 'rm8',
    tipo: TipoManejo.saude,
    descricao: 'Suplemento mineral',
    horario: '19:00',
    quantidade: '30 g',
    concluida: false,
    responsavel: 'João',
  ),
];

Cavalo construirCavaloPrincipal() => Cavalo(
  id: 'isabel-toro-leo',
  nome: 'ISABEL TORO LEO',
  registro: 'P341234',
  principal: true,
  sexo: Sexo.femea,
  nascimento: _d(18, 8, 2018),
  pelagem: 'Castanho',
  raca: 'Quarto de Milha',
  altura: '1,52 m',
  peso: '520 kg',
  descricao:
      'Égua de excepcional habilidade em provas de velocidade. Filha de LEO DO VALE, '
      'campeão de três tambores, e neta de TORO LEO. Possui temperamento equilibrado, '
      'andamento regular e ótima resposta ao treinamento, características típicas da '
      'linhagem Quarter Horse de velocidade.',
  proprietario: const Proprietario(
    nome: 'João da Silva',
    fazenda: 'Fazenda Santa Helena',
    telefone: '(11) 99999-9999',
    cidade: 'Porto Feliz - SP',
  ),
  criador: const Criador(nome: 'Haras Toro Leo', cidade: 'Porto Feliz - SP'),
  pai: paiDoCavalo,
  mae: maeDoCavalo,
  fotoPerfil: '$caminhoImagens/hero.jpg',
  midias: _midias,
  provas: _provas,
);

List<Baia> construirBaias() => [
  Baia(
    numero: '01',
    cavaloId: 'isabel-toro-leo',
    status: StatusBaia.emDia,
    ultimaLimpeza: DateTime(2026, 10, 14, 6, 40),
    manejo: _manejoPadrao(),
    ocorrencias: [
      Ocorrencia(
        id: 'oc1',
        data: DateTime(2026, 10, 3, 9, 20),
        tipo: TipoOcorrencia.saude,
        descricao: 'Ferimento leve na canela dianteira esquerda. Curativo aplicado.',
        responsavel: 'Veterinária Ana Prado',
        resolvida: true,
      ),
      Ocorrencia(
        id: 'oc2',
        data: DateTime(2026, 9, 12, 16, 5),
        tipo: TipoOcorrencia.estrutura,
        descricao: 'Porta da baia com dobradiça solta, ajustada pela manutenção.',
        responsavel: 'Equipe de manutenção',
        resolvida: true,
      ),
      Ocorrencia(
        id: 'oc3',
        data: DateTime(2026, 8, 21, 7, 45),
        tipo: TipoOcorrencia.manejo,
        descricao: 'Mudança no horário da suplementação aprovada pelo tratador.',
        responsavel: 'Carlos',
        resolvida: false,
      ),
    ],
    observacoes: [
      Observacao(
        id: 'ob1',
        data: DateTime(2026, 10, 12, 18, 30),
        autor: 'João da Silva',
        texto:
            'Ajuste na ração da noite: manter 1,5 kg até a prova de novembro. '
            'Animal respondendo bem ao aumento de exercício.',
      ),
      Observacao(
        id: 'ob2',
        data: DateTime(2026, 9, 29, 8, 15),
        autor: 'Marina',
        texto: 'Após a prova de Barretos, aplicar gelo por 20 minutos na manhã seguinte.',
      ),
      Observacao(
        id: 'ob3',
        data: DateTime(2026, 9, 5, 20, 10),
        autor: 'Veterinária Ana Prado',
        texto: 'Vermifugação semestral concluída. Retorno previsto para março.',
      ),
    ],
  ),
  Baia(
    numero: '02',
    cavaloId: 'tornado-do-vale',
    status: StatusBaia.emDia,
    ultimaLimpeza: DateTime(2026, 10, 14, 6, 55),
    manejo: _manejoPadrao(),
    ocorrencias: [
      Ocorrencia(
        id: 'oc4',
        data: DateTime(2026, 10, 1, 11, 0),
        tipo: TipoOcorrencia.manejo,
        descricao: 'Apetite reduzido no período da manhã, normalizado à tarde.',
        responsavel: 'Carlos',
        resolvida: true,
      ),
    ],
    observacoes: [
      Observacao(
        id: 'ob4',
        data: DateTime(2026, 10, 8, 9, 0),
        autor: 'João da Silva',
        texto: 'Iniciar condicionamento para a temporada de 2027.',
      ),
    ],
  ),
  Baia(
    numero: '03',
    cavaloId: 'luna-badger',
    status: StatusBaia.emDia,
    ultimaLimpeza: DateTime(2026, 10, 13, 17, 10),
    manejo: _manejoPadrao(concluido: false),
    ocorrencias: const [],
    observacoes: [
      Observacao(
        id: 'ob5',
        data: DateTime(2026, 9, 30, 7, 30),
        autor: 'Marina',
        texto: 'Égua em descanso após a última prova. Retomar trote leve na próxima semana.',
      ),
    ],
  ),
  Baia(
    numero: '04',
    cavaloId: 'relampago-star',
    status: StatusBaia.manutencao,
    ultimaLimpeza: DateTime(2026, 10, 11, 16, 20),
    manejo: _manejoPadrao(concluido: false),
    ocorrencias: [
      Ocorrencia(
        id: 'oc6',
        data: DateTime(2026, 10, 9, 14, 40),
        tipo: TipoOcorrencia.estrutura,
        descricao: 'Bebedouro automático com vazamento, aguardando peça de reposição.',
        responsavel: 'Equipe de manutenção',
        resolvida: false,
      ),
      Ocorrencia(
        id: 'oc7',
        data: DateTime(2026, 10, 2, 10, 15),
        tipo: TipoOcorrencia.saude,
        descricao: 'Casco posterior direito com sensibilidade. Ferrageiro agendado.',
        responsavel: 'Veterinária Ana Prado',
        resolvida: false,
      ),
    ],
    observacoes: [
      Observacao(
        id: 'ob6',
        data: DateTime(2026, 10, 10, 19, 0),
        autor: 'João da Silva',
        texto: 'Priorizar a troca do bebedouro antes da prova de novembro.',
      ),
    ],
  ),
  Baia(
    numero: '05',
    cavaloId: 'boneca-freckles',
    status: StatusBaia.emDia,
    ultimaLimpeza: DateTime(2026, 10, 14, 7, 5),
    manejo: _manejoPadrao(),
    ocorrencias: const [],
    observacoes: [
      Observacao(
        id: 'ob7',
        data: DateTime(2026, 10, 6, 8, 20),
        autor: 'Carlos',
        texto: 'Animal tranquilo, mantendo a rotina de manejo sem alterações.',
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Plantel (demais cavalos exibidos nas baias)
// ---------------------------------------------------------------------------

const _cavalosExtras = <String, ({String nome, String pelagem, String registro})>{
  'tornado-do-vale': (
    nome: 'TORNADO DO VALE',
    pelagem: 'Alazão',
    registro: 'P347821',
  ),
  'luna-badger': (
    nome: 'LUNA BADGER',
    pelagem: 'Tordilha',
    registro: 'P321554',
  ),
  'relampago-star': (
    nome: 'RELÂMPAGO STAR',
    pelagem: 'Baio',
    registro: 'P355902',
  ),
  'boneca-freckles': (
    nome: 'BONECA FRECKLES',
    pelagem: 'Castanho',
    registro: 'P298441',
  ),
  'estrela-guia': (
    nome: 'ESTRELA GUIA',
    pelagem: 'Tordilha',
    registro: 'P360118',
  ),
  'vento-norte': (
    nome: 'VENTO NORTE',
    pelagem: 'Alazão',
    registro: 'P372640',
  ),
};

/// Nome de um cavalo a partir do identificador, incluindo o plantel secundário.
String nomeDoCavalo(String id) {
  if (id == 'isabel-toro-leo') return 'ISABEL TORO LEO';
  return _cavalosExtras[id]?.nome ?? 'Sem identificação';
}

String pelagemDoCavalo(String id) {
  if (id == 'isabel-toro-leo') return 'Castanho';
  return _cavalosExtras[id]?.pelagem ?? '—';
}

String registroDoCavalo(String id) {
  if (id == 'isabel-toro-leo') return 'P341234';
  return _cavalosExtras[id]?.registro ?? '—';
}

/// Foto de perfil exibida nas listas de baia.
String fotoDoCavalo(String id) => switch (id) {
  'isabel-toro-leo' => '$caminhoImagens/hero.jpg',
  'tornado-do-vale' => '$caminhoImagens/p2.jpg',
  'luna-badger' => '$caminhoImagens/p5.jpg',
  'relampago-star' => '$caminhoImagens/p7.jpg',
  'boneca-freckles' => '$caminhoImagens/p3.jpg',
  _ => '$caminhoImagens/hero.jpg',
};

/// Constrói os demais animais do plantel (ocupantes das baias 02 a 05).
///
/// Os dados são derivados do cavalo principal para manter coerência de haras
/// e proprietário, variando apenas o que identifica cada animal.
List<Cavalo> plantelDeDemonstracao(Cavalo principal) {
  const ordem = ['tornado-do-vale', 'luna-badger', 'relampago-star', 'boneca-freckles'];
  final nascimentos = <String, DateTime>{
    'tornado-do-vale': DateTime(2017, 3, 12),
    'luna-badger': DateTime(2019, 11, 2),
    'relampago-star': DateTime(2016, 6, 25),
    'boneca-freckles': DateTime(2020, 1, 18),
  };
  const alturas = <String, String>{
    'tornado-do-vale': '1,58 m',
    'luna-badger': '1,49 m',
    'relampago-star': '1,55 m',
    'boneca-freckles': '1,47 m',
  };
  const pesos = <String, String>{
    'tornado-do-vale': '545 kg',
    'luna-badger': '480 kg',
    'relampago-star': '530 kg',
    'boneca-freckles': '465 kg',
  };

  return [
    for (final id in ordem)
      if (_cavalosExtras[id] case final dados?)
        Cavalo(
          id: id,
          nome: dados.nome,
          registro: dados.registro,
          sexo: id == 'luna-badger' || id == 'boneca-freckles' ? Sexo.femea : Sexo.macho,
          nascimento: nascimentos[id]!,
          pelagem: dados.pelagem,
          raca: principal.raca,
          altura: alturas[id]!,
          peso: pesos[id]!,
          descricao:
              'Animal do plantel do ${principal.proprietario.fazenda}, '
              'mantido no mesmo manejo e acompanhamento sanitário do haras.',
          proprietario: principal.proprietario,
          criador: principal.criador,
          pai: _avo1,
          mae: _avo3,
          fotoPerfil: fotoDoCavalo(id),
          midias: const [],
          provas: const [],
        ),
  ];
}
