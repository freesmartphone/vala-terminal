/*
 * Vala-Terminal -- a lightweight terminal program
 *
 * (C) 2007-2010 Michael 'Mickey' Lauer <mickey@vanille-media.de>
 * (C) 2009 Aapo Rantalainen
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using Gdk;
using Gtk;
using Vte;

public class ValaTerminal2.MokoTerminal : HBox
{
    private static string fontname;
      public static void set_font(string font){
      fontname = font;
      }

    private uint fontsize;
    private Scrollbar scrollbar;
    private Terminal terminal;

    private static uint starting_fontsize;
      public static void set_starting_fontsize(uint size){
      starting_fontsize=size;
      }

   private static bool use_default_fore_color=true;
   private static uint16 fore_red   ;
   private static uint16 fore_green ;
   private static uint16 fore_blue  ;

   public signal void title_changed();

   public string? get_title()
   {
      // returns null when no title is set!
      return terminal.window_title;
   }

   public static void set_fore_color(uint r,uint g,uint b) {
      use_default_fore_color=false;
      fore_red   = (uint16) r;
      fore_green = (uint16) g;
      fore_blue  = (uint16) b;
      }


   private static bool use_default_back_color=true;
   private static uint16 back_red   ;
   private static uint16 back_green ;
   private static uint16 back_blue  ;

   public static void set_back_color(uint r,uint g,uint b) {
      use_default_back_color=false;
      back_red   = (uint16) r;
      back_green = (uint16) g;
      back_blue  = (uint16) b;
      }

    public static int starting_width;
    public static int starting_height;

    construct {
        stdout.printf( "moko-terminal constructed\n" );

         if (fontname == null)
             fontname = "LiberationMono";

        if (use_default_fore_color)
            {
            fore_red = 0xffff;
            fore_green = 0xffff;
            fore_blue = 0xffff;
            }

        if (use_default_back_color)
            {
            back_red = 0x0000;
            back_green = 0x0000;
            back_blue = 0x0000;
            }

        // may read from gconf at some point?
        fontsize = starting_fontsize;

        terminal = new Vte.Terminal();
        // auto-exit may become a preference at some point?
        terminal.child_exited += term => { destroy(); };
        terminal.eof += term => { destroy(); };
        terminal.window_title_changed += term => { title_changed(); };
        pack_start( terminal, true, true, 0 );

        scrollbar = new VScrollbar( terminal.adjustment );
        pack_start( scrollbar, false, false, 0 );

//        var fore = Gdk.Color() { pixel = 0, red = 0xffff, green = 0xffff, blue = 0xffff };
//        var back = Gdk.Color() { pixel = 0, red = 0x0000, green = 0x0000, blue = 0x0000 };
        var fore = Gdk.Color() { pixel = 0, red = fore_red, green = fore_green, blue = fore_blue };
        var back = Gdk.Color() { pixel = 0, red = back_red, green = back_green, blue = back_blue };

        var colors = new Gdk.Color[] {
            Gdk.Color() { pixel = 0, red = 0x0000, green = 0x0000, blue = 0x0000 },
            Gdk.Color() { pixel = 0, red = 0x8000, green = 0x0000, blue = 0x0000 },
            Gdk.Color() { pixel = 0, red = 0x0000, green = 0x8000, blue = 0x0000 },
            Gdk.Color() { pixel = 0, red = 0x8000, green = 0x8000, blue = 0x0000 },
            Gdk.Color() { pixel = 0, red = 0x0000, green = 0x0000, blue = 0x8000 },
            Gdk.Color() { pixel = 0, red = 0x8000, green = 0x0000, blue = 0x8000 },
            Gdk.Color() { pixel = 0, red = 0x0000, green = 0x8000, blue = 0x8000 },
            Gdk.Color() { pixel = 0, red = 0x8000, green = 0x8000, blue = 0x8000 }
        };

        terminal.set_colors( fore, back, colors );

        update_font();
        terminal.set_scrollback_lines( 1000 );
        terminal.set_mouse_autohide( true );
        terminal.set_cursor_blinks( true );
        terminal.set_backspace_binding( TerminalEraseBinding.ASCII_DELETE);
        // work around bug in VTE. FIXME: Clear with upstream
        terminal.fork_command( (string) 0, (string[]) 0, new string[]{}, Environment.get_variable( "HOME" ), true, true, true );

        if ( starting_width > 0 && starting_height > 0 )
            terminal.set_size( starting_width, starting_height );
    }

    public uint get_font_size()
    {
        return fontsize;
    }

    public void update_font()
    {
        string font = "%s %u".printf( fontname, fontsize );
        terminal.set_font_from_string_full( font, TerminalAntiAlias.FORCE_ENABLE );
    }

    public void zoom_in()
    {
        ++fontsize;
        update_font();
    }

    public void zoom_out()
    {
        --fontsize;
        update_font();
    }

    public void paste()
    {
        terminal.paste_primary();
    }

    public void paste_command( string command )
    {
       terminal.feed_child( command + "\0", -1 );
    }
}

