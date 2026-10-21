import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/escopo.dart';
import 'package:equilink_core/equilink_core.dart';
import '../core/tema.dart';
import '../rotas.dart';
import '../widgets/comuns.dart';

/// Visão geral do haras: indicadores, ocupação das baias e alertas.
class TelaPainel extends StatelessWidget {
  const TelaPainel({super.key});

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);
    final consumo = rep.consumoDiario;
    final maiorConsumo = consumo.isEmpty
        ? 1.0
        : Analise.maiorValor(consumo.map((c) => c.quilos));
    final ocupadas = rep.baias.where((b) => !rep.baiaOrfa(b.cavaloId)).length;
    final semBaia = rep.cavalosSemBaia;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CabecalhoSecao(
          titulo: 'Visão geral',
          subtitulo: 'Situação do haras e do acervo em ${rep.fonte.descricao}',
          icone: Icons.dashboard_outlined,
          acao: FilledButton.icon(
            onPressed: () => context.go(RotasAdmin.cavalos),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Gerenciar dados'),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, restricoes) {
            final colunas = restricoes.maxWidth > 900 ? 4 : (restricoes.maxWidth > 560 ? 2 : 1);
            final itens = [
              Indicador(
                valor: '${rep.cavalos.length}',
                rotulo: 'Animais no acervo',
                icone: Icons.pets_outlined,
              ),
              Indicador(
                valor: '$ocupadas',
                rotulo: 'Baias ocupadas',
                icone: Icons.home_work_outlined,
              ),
              Indicador(
                valor: '${rep.manejoPendenteTotal}',
                rotulo: 'Tarefas pendentes',
                icone: Icons.checklist_outlined,
                destaque: true,
              ),
              Indicador(
                valor: '${rep.ocorrenciasAbertasTotal}',
                rotulo: 'Ocorrências abertas',
                icone: Icons.report_problem_outlined,
                cor: AdminCores.vermelho,
              ),
            ];
            return GridView.count(
              crossAxisCount: colunas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: colunas == 1 ? 4 : 2.6,
              children: itens,
            );
          },
        ),
        const SizedBox(height: 18),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabecalhoSecao(
                titulo: 'Ocupação das baias',
                subtitulo: ocupadas == 0
                    ? 'Nenhuma baia cadastrada'
                    : plural(ocupadas, 'animal alojado', 'animais alojados'),
                icone: Icons.home_work_outlined,
              ),
              const SizedBox(height: 16),
              if (rep.baias.isEmpty)
                const Vazio(
                  icone: Icons.home_work_outlined,
                  titulo: 'Sem baias',
                  descricao: 'Cadastre animais e baias para acompanhar o manejo aqui.',
                ),
              for (final baia in rep.baiasOrdenadas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminCores.superficieSuave,
                      borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 68,
                          child: Text(
                            'Baia ${baia.numero}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AdminCores.dourado,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            rep.nomeCavalo(baia.cavaloId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Etiqueta.status(baia.status.rotulo),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: Text(
                            '${baia.pendentes} de ${baia.manejo.length} pendentes',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AdminCores.textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (semBaia.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CabecalhoSecao(
                    titulo: 'Animais sem baia',
                    subtitulo: 'Cadastrados no acervo, mas sem alojamento definido',
                    icone: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cavalo in semBaia)
                        Chip(
                          avatar: const Icon(Icons.pets, size: 14),
                          label: Text(cavalo.nome),
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Consumo diário estimado',
                subtitulo: 'Somatório da rotina de manejo de todas as baias',
                icone: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),
              if (consumo.isEmpty)
                const Vazio(icone: Icons.inventory_2_outlined, titulo: 'Sem dados de consumo'),
              for (final item in consumo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          item.insumo,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AdminRaios.total),
                          child: SizedBox(
                            height: 8,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: ((item.quilos / maiorConsumo) * 1000).round().clamp(1, 1000),
                                  child: const ColoredBox(color: AdminCores.dourado),
                                ),
                                Expanded(
                                  flex:
                                      1000 - ((item.quilos / maiorConsumo) * 1000).round().clamp(1, 1000),
                                  child: const ColoredBox(color: AdminCores.superficieSuave),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 96,
                        child: Text(
                          '${item.quilos.toStringAsFixed(1).replaceAll('.', ',')} kg/dia',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminCores.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
