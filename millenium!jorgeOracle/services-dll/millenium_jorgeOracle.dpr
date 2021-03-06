library millenium_jorgeOracle;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  wtsmemorym_intf,
  wtsServerObjs in 'Z:\WDTS\server\common\wtsServerObjs.pas',
  millenium_jorgeOracle_clientes in 'millenium_jorgeOracle_clientes.pas',
  millenium_jorgeOracle_estoques in 'millenium_jorgeOracle_estoques.pas',
  millenium_jorgeOracle_produtos in 'millenium_jorgeOracle_produtos.pas',
  oracle_utils in 'oracle_utils.pas';

exports
  wtsLibEntry,
  wtsLibShutdown;

begin

end.
