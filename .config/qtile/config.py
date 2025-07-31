from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.widget import base
import subprocess
import os

class DynamicBattery(base.ThreadPoolText):
    def __init__(self, **config):
        super().__init__("", **config)
        self.add_defaults(base.ThreadPoolText.defaults)
        
    def poll(self):
        text, color = get_battery_status()
        # Update the foreground color
        self.foreground = color
        return text

def get_battery_capacity_once():
    try:
        import subprocess
        result = subprocess.run(['sudo', 'tlp-stat', '-b'], capture_output=True, text=True, timeout=5)
        
        for line in result.stdout.split('\n'):
            if 'Capacity' in line and '=' in line:
                # Extract the value after '=' and before '[%]'
                capacity_part = line.split('=')[1].strip()
                capacity_value = capacity_part.split('[')[0].strip()
                return f"{capacity_value}%"
        
        return "N/A"
    except:
        return "Error"

def get_battery_status():
    try:
        with open('/sys/class/power_supply/BATT/status', 'r') as f:
            status = f.read().strip()
        with open('/sys/class/power_supply/BATT/capacity', 'r') as f:
            capacity = int(f.read().strip())
        
        if status == 'Full':
            return ('Full', '#FFFFFF')
        elif status == 'Charging':
            return (f'{capacity}% chrg', '#FFFFFF')
        else:  # Discharging or other
            color = '#FF0000' if capacity <= 15 else '#FFFFFF'
            return (f'{capacity}%', color)
    except:
        return ('Unknown', '#FFFFFF')

@hook.subscribe.startup_once
def autostart():
    subprocess.run(["xsetroot", "-cursor_name", "left_ptr"])
    subprocess.Popen(["nm-applet"]) 
    subprocess.Popen(["flatpak", "run", "org.flameshot.Flameshot"])
    subprocess.Popen(["sh", "-c", "while true; do xclip -selection clipboard -t text/plain -o 2>/dev/null | cliphist store 2>/dev/null; sleep 1; done"])
    subprocess.Popen(["dunst"])
    # Autostart systray applications
    # subprocess.Popen(["flatpak", "run", "com.slack.Slack"])
    # subprocess.Popen(["flatpak", "run", "com.protonvpn.www"])
    # subprocess.Popen(["flatpak", "run", "com.discordapp.Discord"])
    # subprocess.Popen(["flatpak", "run", "com.protonvpn.www"])

mod = "mod4"
terminal = "st"

# Keybinds
keys = [
    # Key([mod], "a", , desc=""),  # a - removed rofi
    Key([mod], "b",lazy.spawn("sudo /usr/local/bin/battery-toggle"), desc="Toggle battery charge threshold (80%/100%)"),
    Key([mod], "c", lazy.spawn("sh -c \"cliphist list | dmenu -p 'Clipboard' | cliphist decode | xclip -selection clipboard\""), desc="Show clipboard history"),
    Key([mod, "shift"], "c", lazy.spawn("sh -c \"cliphist wipe && dunstify 'Clipboard Cleared' -t 2000\""), desc="Clear clipboard history"),
    # Key([mod], "d", , desc=""),  # d
    # Key([mod], "e", , desc=""),  # e - removed lf
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window"),  # f
    # Key([mod], "g", , desc=""),  # g
    # Key([mod], "h", , desc=""),  # h
    # Key([mod], "i", , desc=""),  # i
    # Key([mod], "j", , desc=""),  # j
    # Key([mod], "k", , desc=""),  # k
    Key([mod], "l", lazy.spawn("slock"), desc="Lock screen"),  # l
    # Key([mod], "m", , desc=""),  # m
    # Key([mod], "n", , desc=""),  # n
    # Key([mod], "o", , desc=""),  # o
    # Key([mod], "p", , desc=""),  # p
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),  # q
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Shutdown Qtile"),  # q + shift
    # Key([mod], "r", , desc=""),  # r
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),  # r + control
    Key([mod], "s", lazy.spawn("flatpak run org.flameshot.Flameshot gui"), desc="Take screenshot with flameshot"),
    # Key([mod], "t", , desc=""),  # t
    # Key([mod], "u", , desc=""),  # u
    # Key([mod], "v", , desc=""),  # v
    Key([mod], "w", lazy.spawn("firefox")),  # w
    # Key([mod], "x", , desc=""),  # x
    # Key([mod], "y", , desc=""),  # y
    # Key([mod], "z", , desc=""),  # z
    Key([mod], "return", lazy.next_layout(), desc="Toggle between layouts"),  # return
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle between split and unsplit sides of stack"),  # return + shift
    Key([mod], "space", lazy.group['scratchpad'].dropdown_toggle('terminal'), desc="Toggle terminal scratchpad"),  # space
    Key([mod], "Tab", lazy.layout.next(), desc="Move window focus to other window"),  # tab
    Key([mod], "Right", lazy.screen.next_group(), desc="Move to next group"),
    Key([mod], "Left", lazy.screen.prev_group(), desc="Move to previous group"),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set 64+"), desc="Increase brightness"),  # brightness up
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 64-"), desc="Decrease brightness"),  # brightness down
    Key([], "XF86AudioRaiseVolume", lazy.spawn("wpctl set-volume @DEFAULT_SINK@ 0.1+"), desc="Increase volume"),  # volume up
    Key([], "XF86AudioLowerVolume", lazy.spawn("wpctl set-volume @DEFAULT_SINK@ 0.1-"), desc="Decrease volume"),  # volume down
    Key([], "XF86AudioMute", lazy.spawn("wpctl set-mute @DEFAULT_SINK@ toggle"), desc="Toggle mute"),  # volume mute
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

groups = [Group(i) for i in "12345"]

for i in groups:
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
            Key([mod, "control"], i.name, lazy.window.togroup(i.name, switch_group=False))
	    # Or, use below if you prefer not to switch to that group.
            # # mod + shift + group number = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

# Add scratchpad group AFTER regular groups are processed
groups.append(ScratchPad("scratchpad", [
    DropDown("terminal", terminal, 
             width=0.996, height=0.99, x=0.002, y=0.003, 
             opacity=0.92,
	     on_focus_lost_hide=False),
]))

layouts = [
    layout.MonadWide(
    	ratio=0.70,
    	border_focus='#67608B',
	border_normal='#290F34',
	border_width=1,
	margin=6,
	),
    layout.Max(),
]

widget_defaults = dict(
    font="sans",
    fontsize=14,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
			background="#00000000",
    			highlight_method='border',
    			inactive='#444444',  # inactive group text color
    			active='#FFFFFF',    # active group text color
    			block_highlight_text_color='#FFFFFF',
    			borderwidth=1,
		),
		widget.Spacer(
			length=10,
		),
		widget.CurrentLayout(
			max_chars=2,
			scroll=True,
			width=60,
		),
		widget.Spacer(
			background="#00000000",
			length=10,
		),
		widget.Systray(),
		widget.Spacer(
			background="#00000000",
			length=1194,
		),
                widget.Clock(
			fontsize=16,
			format='%H:%M',  # Start with time
    			foreground='#FFFFFF',  # All white text
    			background='#00000000',
		),
		widget.Spacer(),
		widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
		widget.TextBox(
			text="  ",
    			background="#00000000",
    			foreground="#777777",
    			padding=0,
		),
		widget.Volume(
			background="#00000000",
    			foreground="#FFFFFF",
    			fmt="{}",  # Just shows percentage like "45%"
    			update_interval=0.1,  # Real-time updates
			mouse_callbacks={
        		'Button1': lambda: qtile.spawn('pavucontrol')
    			},
		),
		widget.TextBox(
			text=" ",
    			background="#00000000",
    			foreground="#B8A000",
    			padding=0,
		),
		widget.Backlight(
			background="#00000000",
			foreground="#FFFFFF",
			fmt="{}",
			backlight_name="amdgpu_bl0",
			update_interval=0.1,
		),
		widget.TextBox(
			text="   ",
    			background="#00000000",
    			foreground="#00B399",
    			padding=0,
		),
		DynamicBattery(
			background="#00000000",
    			foreground="#FFFFFF",
    			update_interval=30,
		),
		widget.TextBox(
			text="   ",
    			background="#00000000",
    			foreground="#666666",
    			padding=0,
		),
		widget.TextBox(
    			text=get_battery_capacity_once(),
    			background="#00000000",
    			foreground="#FFFFFF",
    			padding=3,
		),
            ],
            24,
	    background='#00000000',
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    border_focus='#67608B',
    border_normal='#67608B',
    border_width=1,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
