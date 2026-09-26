/*
 * RescueSystemWindow.vala - autoBack rescue system manager
 *
 * One-click build / install / status of the independent btrfs rescue
 * system (EFISTUB UKI). Backend logic lives in the rescue scripts
 * installed alongside autoBack.
 *
 * GPL-2.0-or-later (matches autoBack licensing)
 */

using GLib;
using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;

public class RescueSystemWindow : Gtk.Window {

	private Gtk.TextView txt_log;
	private Gtk.Button btn_build;
	private Gtk.Button btn_install;
	private Gtk.Button btn_status;

	// candidate locations of the rescue build scripts
	private static string[] script_dirs = {
		"/usr/share/autoback/rescue/scripts",
		"/usr/share/autoback/rescue",
		"/opt/autoback/rescue"
	};

	public RescueSystemWindow(Gtk.Window? parent) {

		set_title(_("Rescue System"));
		set_default_size(760, 520);
		set_position(Gtk.WindowPosition.CENTER_ON_PARENT);
		set_modal(true);
		if (parent != null) { set_transient_for(parent); }
		set_resizable(true);
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

		var vbox_main = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
		vbox_main.margin = 10;
		add(vbox_main);

		var lbl_info = new Gtk.Label(_("Build an independent rescue system (EFISTUB UKI) and register it in your firmware. The rescue system can restore this system even when GRUB and the OS itself are broken."));
		lbl_info.wrap = true;
		lbl_info.xalign = 0.0f;
		vbox_main.add(lbl_info);

		var hbox_actions = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		vbox_main.add(hbox_actions);

		btn_build = new Gtk.Button.with_label(_("1. Build Rescue Image"));
		btn_build.set_tooltip_text(_("Pin current kernel modules and build recovery.efi"));
		hbox_actions.add(btn_build);

		btn_install = new Gtk.Button.with_label(_("2. Install to ESP"));
		btn_install.set_tooltip_text(_("Write recovery.efi to the EFI System Partition and register a firmware boot entry"));
		hbox_actions.add(btn_install);

		btn_status = new Gtk.Button.with_label(_("3. Check Status"));
		btn_status.set_tooltip_text(_("Check ESP entry and firmware boot registration"));
		hbox_actions.add(btn_status);

		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		scroll.vexpand = true;
		vbox_main.add(scroll);

		txt_log = new Gtk.TextView();
		txt_log.editable = false;
		txt_log.monospace = true;
		txt_log.wrap_mode = Gtk.WrapMode.NONE;
		txt_log.left_margin = 6;
		txt_log.right_margin = 6;
		scroll.add(txt_log);

		var hbox_log = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		vbox_main.add(hbox_log);

		var btn_log = new Gtk.Button.with_label(_("View autoBack Log (/var/log/autoback.log)"));
		btn_log.halign = Gtk.Align.START;
		hbox_log.add(btn_log);

		var hbox_close = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		vbox_main.add(hbox_close);

		var btn_close = new Gtk.Button.with_label(_("Close"));
		btn_close.halign = Gtk.Align.END;
		hbox_close.add(btn_close);

		btn_log.clicked.connect(() => { show_log(); });
		btn_close.clicked.connect(() => { this.destroy(); });
		btn_build.clicked.connect(() => { run_action("build"); });
		btn_install.clicked.connect(() => { run_action("install"); });
		btn_status.clicked.connect(() => { run_action("status"); });

		show_all();
		show_log();
		run_action("status");
	}

	private void show_log() {
		log_append("=== /var/log/autoback.log ===");
		string content = "";
		try {
			var f = GLib.File.new_for_path("/var/log/autoback.log");
			uint8[] data;
			f.load_contents(null, out data, null);
			content = (string) data;
		} catch (Error e) {
			content = "(empty - no autoBack activity logged yet)";
		}
		log_append(content.strip());
		log_append("=== end of log ===");
	}

	private string script_path(string name) {
		foreach (var dir in script_dirs) {
			string p = dir + "/" + name;
			if (file_exists(p)) { return p; }
		}
		return "";
	}

	private void log_append(string text) {
		txt_log.buffer.text += text;
		if (text.length == 0 || text.get_char(text.length - 1) != '\n') {
			txt_log.buffer.text += "\n";
		}
		// auto-scroll to end
		var mark = txt_log.buffer.get_insert();
		txt_log.scroll_to_mark(mark, 0.0, false, 0.0, 1.0);
	}

	private void run_action(string action) {
		string script = "";
		string args = "";

		switch (action) {
			case "build":
				script = script_path("build-initramfs.sh");
				args = "";
				break;
			case "install":
				script = script_path("install-phase1.sh");
				args = "";
				break;
			case "status":
				log_append("=== Rescue system status ===");
				if (file_exists("/boot/efi/EFI/recovery/recovery.efi")) {
					log_append("ESP entry : /boot/efi/EFI/recovery/recovery.efi FOUND");
				} else {
					log_append("ESP entry : recovery.efi NOT installed");
				}
				string so, se;
				exec_sync("efibootmgr 2>/dev/null | grep -i rescue", out so, out se);
				if (so.strip().length > 0) {
					log_append("Firmware  : " + so.strip());
				} else {
					log_append("Firmware  : no rescue boot entry");
				}
				foreach (var dir in script_dirs) {
					bool ok = FileUtils.test(dir + "/build-initramfs.sh", GLib.FileTest.EXISTS);
					log_append("probe    : %s/build-initramfs.sh => %s".printf(dir, ok.to_string()));
				}
				log_append("Scripts   : " + ((script_path("build-initramfs.sh").length > 0) ? "installed" : "NOT INSTALLED (install autoBack rescue scripts)"));
				return;
		}

		if (script.length == 0) {
			log_append("!! rescue scripts not found - probing:");
			foreach (var dir in script_dirs) {
				bool ok = FileUtils.test(dir + "/build-initramfs.sh", GLib.FileTest.EXISTS);
				log_append("probe    : %s/build-initramfs.sh => %s".printf(dir, ok.to_string()));
			}
			return;
		}

		log_append("=== Running: %s %s ===".printf(script, args));
		string so, se;
		int ret = exec_sync("sh '%s' %s".printf(script, args), out so, out se);
		if (so.length > 0) { log_append(so); }
		if (se.length > 0) { log_append("STDERR: " + se); }
		log_append("=== exit code: %d ===".printf(ret));
	}
}
