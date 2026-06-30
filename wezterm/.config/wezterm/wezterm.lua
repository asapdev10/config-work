-- WezTerm config — minimal alacritty-like feel, ported settings noted below.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ── Minimal chrome ───────────────────────────────────────────────────────────
-- Tab bar: flat retro style, always visible (hosts the clock in the right status)
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.window_decorations = 'RESIZE' -- no title bar, keep resize borders
config.audible_bell = 'Disabled'
config.cursor_blink_rate = 0
config.animation_fps = 1 -- no cursor/window easing animations

-- ── Carried over from alacritty ──────────────────────────────────────────────
-- font: JetBrainsMono NF 13 (fallback name differs on some installs)
config.font = wezterm.font_with_fallback {
  'JetBrainsMono NF',
  'JetBrainsMono Nerd Font',
}
config.font_size = 13.0

-- window.padding = { x = 5, y = 5 }
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 }

-- colors: Challenger Deep (from alacritty themes/challenger_deep.toml)
config.colors = {
  foreground = '#cbe1e7',
  background = '#121212', -- neutral near-black (theme's purple #1e1c31 swapped out)
  cursor_bg = '#fbfcfc',
  cursor_fg = '#ff271d',
  ansi = { '#141228', '#ff5458', '#62d196', '#ffb378', '#65b2ff', '#906cff', '#63f2f1', '#a6b3cc' },
  brights = { '#565575', '#ff8080', '#95ffa4', '#ffe9aa', '#91ddff', '#c991e1', '#aaffe4', '#cbe3e7' },

  -- flat tab bar: blends into the background, dim inactive tabs
  tab_bar = {
    background = '#121212',
    active_tab = { bg_color = '#121212', fg_color = '#cbe1e7', intensity = 'Bold' },
    inactive_tab = { bg_color = '#121212', fg_color = '#565575' },
    inactive_tab_hover = { bg_color = '#1e1c31', fg_color = '#cbe1e7' },
  },
}

-- F1 → vi-style mode (alacritty: ToggleViMode). Escape/q exit, as before.
config.keys = {
  { key = 'F1', action = wezterm.action.ActivateCopyMode },
}

-- Hide the tab title when there's only one tab (bar stays up for the clock)
wezterm.on('format-tab-title', function(_, tabs)
  if #tabs == 1 then
    return ''
  end
  -- nil → default title formatting for 2+ tabs
end)

-- Clock on the right of the tab bar, dimmed to match inactive tabs
wezterm.on('update-status', function(window, _)
  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#565575' } },
    { Text = wezterm.strftime '%a %b %-d  %H:%M ' },
  })
end)

return config
