{pkgs, ...}: {
  services.dunst = {
    enable = true;

    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = 300;
        height = 300;
        origin = "top-right";
        offset = "10x10";
        scale = 0;
        notification_limit = 0;
        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;
        indicate_hidden = true;
        transparency = 5;
        separator_height = 2;
        padding = 6;
        horizontal_padding = 6;
        text_icon_padding = 0;
        frame_width = 3;
        frame_color = "#000000";
        separator_color = "frame";
        sort = false;
        idle_threshold = 0;
        font = "Iosevka 11";
        line_height = 3;
        markup = "full";
        format = "<b>%s</b>\n%b";
        alignment = "center";
        vertical_alignment = "center";
        show_age_threshold = -1;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        word_wrap = true;
        icon_position = "left";
        min_icon_size = 64;
        max_icon_size = 64;
        sticky_history = true;
        history_length = 15;
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst:";
        browser = "firefox";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 5;
        ignore_dbusclose = false;
        force_xinerama = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };
      experimental = {
        per_monitor_dpi = false;
      };
      urgency_low = {
        frame_color = "#BCBF30";
        background = "#181818";
        foreground = "#E4E4E4";
        timeout = 4;
      };
      urgency_normal = {
        frame_color = "#FFDD33";
        background = "#181818";
        foreground = "#E4E4E4";
        timeout = 6;
      };
      urgency_critical = {
        frame_color = "#F43841";
        background = "#181818";
        foreground = "#E4E4E4";
        timeout = 8;
      };
    };

    iconTheme = {
      package = pkgs.tela-circle-icon-theme;
      name = "Tela circle dark";
      size = "64x64";
    };
  };
}
