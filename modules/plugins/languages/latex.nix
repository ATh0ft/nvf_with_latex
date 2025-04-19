{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.lists) isList;
  inherit (lib.types) bool enum either package listOf str;
  inherit (lib.nvim.lua) expToLua toLuaObject;
  inherit (lib.nvim.types) diagnostics mkGrammarOption mkPluginSetupOption;
  inherit (lib.nvim.dag) entryAnywhere;

  cfg = config.vim.languages.latex;
  defaultServer = "texlab";

  servers = {
    texlab = {
      package = pkgs.texlab;
      lspConfig = ''
        lspconfig.texlab.setup{
          capabilities = capabilities,
          on_attach = default_on_attach,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''{"${cfg.lsp.package}/bin/texlab"}''
        },
        }
      '';
    };
  };
in {
  options.vim.languages.latex = {
    enable = mkEnableOption "LaTeX language support";

    treesitter = {
      enable = mkOption {
        type = bool;
        default = config.vim.languages.enableTreesitter;
        description = "Enable LaTeX treesitter support";
      };
      texPackage = mkGrammarOption pkgs "latex";
    };

    lsp = {
      enable =
        mkEnableOption "Enable LaTeX LSP support"
        // {
          default = config.vim.languages.enableLSP;
        };

      server = mkOption {
        type = enum (attrNames servers);
        default = defaultServer;
        description = "LaTeX LSP server to use";
      };

      package = mkOption {
        type = either package (listOf str);
        default = servers.${cfg.lsp.server}.package;
        description = "LaTeX LSP server package or command list";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.texPackage];
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.latex-lsp = servers.${cfg.lsp.server}.lspConfig;
    })
  ]);
}
