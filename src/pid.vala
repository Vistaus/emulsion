/*
 * Copyright (c) 2021-2022 Lains
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
namespace Emulsion {
    [GtkTemplate (ui = "/io/github/lainsce/Emulsion/pid.ui")]
    public class PaletteImportDialog : Adw.Window {
        const string COLORED_SURFACE = "* { background: %s; }";

        [GtkChild]
        unowned Gtk.Box color_box;
        [GtkChild]
        unowned Gtk.Button ok_button;
        [GtkChild]
        unowned Gtk.Button cancel_button;
        [GtkChild]
        unowned Gtk.Button image;
        [GtkChild]
        unowned Gtk.Label file_label;
        [GtkChild]
        unowned Gtk.Image file_image;

        private MainWindow win = null;
        private File file;
        private Utils.Palette palette;

        public PaletteImportDialog (MainWindow win) {
            this.win = win;
        }

        construct {
            color_box.get_style_context ().add_class ("palette");
            color_box.set_overflow(Gtk.Overflow.HIDDEN);
            color_box.set_margin_bottom (12);
            color_box.set_margin_end (12);
            color_box.set_margin_start (12);
            color_box.set_visible (false);
            file_label.set_visible (true);
            file_image.set_visible (true);
            image.set_sensitive (true);
            image.set_margin_top (12);
            ok_button.set_sensitive (false);

            cancel_button.clicked.connect (() => {
                this.dispose ();
            });

            ok_button.clicked.connect (() => {
                if (palette == null) {
                    this.dispose ();
                }

                string[] n;
                if (palette.dark_vibrant_swatch != null)
                    n += Utils.make_hex(palette.dark_vibrant_swatch.red, palette.dark_vibrant_swatch.green, palette.dark_vibrant_swatch.blue);
                if (palette.vibrant_swatch != null)
                    n += Utils.make_hex(palette.vibrant_swatch.red, palette.vibrant_swatch.green, palette.vibrant_swatch.blue);
                if (palette.light_vibrant_swatch != null)
                    n += Utils.make_hex(palette.light_vibrant_swatch.red, palette.light_vibrant_swatch.green, palette.light_vibrant_swatch.blue);
                if (palette.dark_muted_swatch != null)
                    n += Utils.make_hex(palette.dark_muted_swatch.red, palette.dark_muted_swatch.green, palette.dark_muted_swatch.blue);
                if (palette.muted_swatch != null)
                    n += Utils.make_hex(palette.muted_swatch.red, palette.muted_swatch.green, palette.muted_swatch.blue);
                if (palette.light_muted_swatch != null)
                    n += Utils.make_hex(palette.light_muted_swatch.red, palette.light_muted_swatch.green, palette.light_muted_swatch.blue);
                if (palette.muted_swatch != null)
                    n += Utils.make_hex(palette.dominant_swatch.red, palette.dominant_swatch.green, palette.dominant_swatch.blue);
                if (palette.light_muted_swatch != null)
                    n += Utils.make_hex(palette.body_swatch.red, palette.body_swatch.green, palette.body_swatch.blue);

                var a = new PaletteInfo ();
                a.palname = "%s".printf(file.get_basename().replace(".jpg","").replace(".png",""));
                a.colors = new Gee.HashMap<string, string> ();

                for (int i = 0; i < n.length; i++) {
                    a.colors.set (n[i], n[i]);
                }

                win.palettestore.append (a);
                win.palette_label.set_visible(true);
                win.palette_stack.set_visible_child_name ("palfull");
                win.search_button.set_visible(true);
                this.dispose ();
            });
        }

        [GtkCallback]
        private void on_clicked () {
            var chooser = new Gtk.FileChooserNative ((_("Import")), win, Gtk.FileChooserAction.OPEN, null, null);

            var png_filter = new Gtk.FileFilter ();
            png_filter.set_filter_name (_("Picture"));
            png_filter.add_pattern ("*.png");
            png_filter.add_pattern ("*.jpg");

            chooser.add_filter (png_filter);

            chooser.response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.OK:
                    case Gtk.ResponseType.ACCEPT:
                    case Gtk.ResponseType.APPLY:
                    case Gtk.ResponseType.YES:
                        try {
                            file = null;
                            file = File.new_for_uri (chooser.get_file ().get_uri ());
						    var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());
                            pixbuf = pixbuf.scale_simple (file_image.get_allocated_width (), file_image.get_allocated_height ()*2, Gdk.InterpType.BILINEAR);
                            file_image.set_from_pixbuf (pixbuf);

                            image.set_sensitive (false);
                            file_image.set_pixel_size (256);
                            image.get_style_context ().remove_class ("dim-label");

                            var palette = new Utils.Palette.from_pixbuf (pixbuf);
                            palette.generate_async.begin (() => {
                                set_colors (palette);
                            });

                            color_box.set_visible (true);
                            file_label.set_visible (false);
                            ok_button.set_sensitive (true);
                        } catch {

                        }
                        break;
                    case Gtk.ResponseType.NO:
                    case Gtk.ResponseType.CANCEL:
                    case Gtk.ResponseType.CLOSE:
                    case Gtk.ResponseType.DELETE_EVENT:
                        chooser.dispose ();
                        break;
                    default:
                        break;
                }
            });

            chooser.show ();
        }

        private void set_colors (Utils.Palette palette) {
            while (color_box.get_last_child () != null) {
                color_box.get_first_child ().destroy ();
            }
            this.palette = palette;

            // Checking for null avoids growing palette's colors that aren't there.
            if (palette.dark_vibrant_swatch != null)
                add_swatch (palette.dark_vibrant_swatch, "Dark vibrant color");
            if (palette.vibrant_swatch != null)
                add_swatch (palette.vibrant_swatch, "Vibrant color");
            if (palette.light_vibrant_swatch != null)
                add_swatch (palette.light_vibrant_swatch, "Light vibrant color");
            if (palette.dark_muted_swatch != null)
                add_swatch (palette.dark_muted_swatch, "Dark muted color");
            if (palette.muted_swatch != null)
                add_swatch (palette.muted_swatch, "Muted color");
            if (palette.light_muted_swatch != null)
                add_swatch (palette.light_muted_swatch, "Light muted color");
            if (palette.body_swatch != null)
                add_swatch (palette.body_swatch, "Body color");
            if (palette.dominant_swatch != null)
                add_swatch (palette.dominant_swatch, "Dominant color");
        }

        private void add_swatch (Utils.Palette.Swatch? swatch, string tooltip) {
            if (swatch == null) return;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.set_size_request (48, 48);
            box.set_hexpand (false);
            box.tooltip_text = tooltip;

            var provider = new Gtk.CssProvider ();
            var context = box.get_style_context ();
            Gdk.RGBA rgba = {swatch.R, swatch.G, swatch.B, swatch.A};
            var css = COLORED_SURFACE.printf (rgba.to_string ());
            provider.load_from_data (css.data);
            context.add_provider (provider, 9999);

            color_box.append (box);
        }
    }
}
