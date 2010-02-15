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
using Gtk;

static const uint DEFAULT_FONTSIZE = 5;
static const bool DEFAULT_START_VERTICAL = false;

public class ValaTerminal2.MainWindow : Window
{
    private Box box;
    private Box toolbar;
    private Notebook notebook;

    private ToolButton btn_new;
    private ToolButton btn_delete;
    private ToolButton btn_zoom_in;
    private ToolButton btn_zoom_out;
    private ToolButton btn_paste;
    private ToolButton btn_prev_tab;
    private ToolButton btn_next_tab;
    private Label tab_counter;
    private ToolButton btn_rotate;
    private ToolButton btn_fullscreen;

    private static string initial_command;
    private static string[] initial_command_line;
    private bool vertical;  /* true, if toolbar is oriented vertically */
    private bool fullscreen_; /* true, if terminal is shown fullscreen. underscore because gtk.window has function named fullscreen*/

    /* because of bug http://bugzilla.gnome.org/show_bug.cgi?id=547135,
    we just pass whole commandline to the terminal */
    private static string hack_command;

    public MainWindow(bool start_vertical, bool start_fullscreen)
    {
        title = "Terminal";
        destroy += Gtk.main_quit;
        vertical= start_vertical;
        fullscreen_= start_fullscreen;

        setup_toolbar();
        setup_notebook();

        if (vertical)
        {
            box = new Gtk.HBox( false, 0 );
            box.pack_start( notebook, true, true, 0 );
            box.pack_start( toolbar, false, false, 0 );
        }
        else
        {
            box = new Gtk.VBox( false, 0 );
            box.pack_end( notebook, true, true, 0 );
            box.pack_end( toolbar, false, false, 0 );
        }
        add( box );

        box.set_focus_child(notebook);

        notebook.page_removed += (o, page, num) => {
            stdout.printf( "on_page_removed\n");
            if ( notebook.get_n_pages() == 0 )
                Gtk.main_quit();
            else
                update_toolbar();
        };

        if (fullscreen_)
            this.fullscreen();

        update_toolbar();
    }

    public void setup_command( string command )
    {
        initial_command = command + "\n";
    }

    public void setup_toolbar()
    {
        if (vertical)
            toolbar = new Gtk.VBox( false, 0 );
        else
            toolbar = new Gtk.HBox( false, 0 );

        btn_new = new Gtk.ToolButton.from_stock( STOCK_NEW );
        btn_new.clicked += on_new_clicked;
        toolbar.pack_start( btn_new, false, false, 0 );

        btn_delete = new Gtk.ToolButton.from_stock( STOCK_DELETE );
        btn_delete.clicked += on_delete_clicked;
        toolbar.pack_start( btn_delete, false, false, 0 );

        //toolbar.insert( new Gtk.SeparatorToolItem(), 2 );

        btn_zoom_in = new Gtk.ToolButton.from_stock( STOCK_ZOOM_IN );
        btn_zoom_in.clicked += on_zoom_in_clicked;
        toolbar.pack_start( btn_zoom_in, false, false, 0 );

        btn_zoom_out = new Gtk.ToolButton.from_stock( STOCK_ZOOM_OUT );
        btn_zoom_out.clicked += on_zoom_out_clicked;
        toolbar.pack_start( btn_zoom_out, false, false, 0 );

        //toolbar.insert( new Gtk.SeparatorToolItem(), 5 );

        btn_paste = new Gtk.ToolButton.from_stock( STOCK_PASTE );
        btn_paste.clicked += on_paste_clicked;
        toolbar.pack_start( btn_paste, false, false, 0 );

        //toolbar.insert( new Gtk.SeparatorToolItem(), 7 );


        btn_prev_tab = new Gtk.ToolButton.from_stock( STOCK_GO_BACK );
        btn_prev_tab.clicked += on_prev_tab_clicked;
        btn_prev_tab.set_sensitive( false);

        toolbar.pack_start( btn_prev_tab, false, false, 0 );

        btn_next_tab = new Gtk.ToolButton.from_stock( STOCK_GO_FORWARD );
        btn_next_tab.clicked += on_next_tab_clicked;
        btn_next_tab.set_sensitive( false);

        toolbar.pack_start( btn_next_tab, false, false, 0 );

        tab_counter = new Label("");
        toolbar.pack_start( tab_counter, false, false, 0 );

        //toolbar.insert( new Gtk.SeparatorToolItem(), 11 );

        btn_rotate = new Gtk.ToolButton.from_stock( STOCK_REFRESH );
        btn_rotate.clicked += on_rotate_clicked;
        btn_rotate.set_label ("Rotate");
        toolbar.pack_start( btn_rotate, false, false, 0 );

        btn_fullscreen = new Gtk.ToolButton.from_stock( STOCK_FULLSCREEN );

        //btn_fullscreen.add_accelerator( "fullscreen", new Gtk.AccelGroup(), 'f', 0, Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE );
        
        btn_fullscreen.clicked += on_fullscreen_clicked;
        btn_fullscreen.set_label ("Fullscreen");
        toolbar.pack_start( btn_fullscreen, false, false, 0 );
    }

    public void setup_notebook()
    {
        notebook = new Gtk.Notebook();
        notebook.set_tab_pos( PositionType.BOTTOM );
        notebook.set_show_tabs(false);
        notebook.set_show_border(false);

        var terminal = new ValaTerminal2.MokoTerminal();
        notebook.append_page( terminal, new Image.from_stock( STOCK_INDEX, IconSize.LARGE_TOOLBAR ) );
        notebook.child_set (terminal, "tab-expand", true, null );
        /* see bug: http://bugzilla.gnome.org/show_bug.cgi?id=547135 */
        if ( hack_command != null )
            terminal.paste_command(hack_command);
    }

    private void on_new_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_new_clicked\n" );
        var terminal = new ValaTerminal2.MokoTerminal();
        notebook.append_page( terminal, new Image.from_stock( STOCK_INDEX, IconSize.LARGE_TOOLBAR ) );
        notebook.child_set (terminal, "tab-expand", true, null );
        notebook.show_all();
        notebook.set_current_page(notebook.get_n_pages()-1); /*jump to that new tab*/
        update_toolbar();
    }

    private void on_delete_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_delete_clicked\n" );
        var page = notebook.get_nth_page( notebook.get_current_page() );
        page.destroy();
        // update_toolbar will be called through the page-removed signal handler
    }

    private void on_zoom_in_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_zoom_in_clicked\n" );
        ValaTerminal2.MokoTerminal terminal = (ValaTerminal2.MokoTerminal) notebook.get_nth_page( notebook.get_current_page() );
        terminal.zoom_in();
        update_toolbar();
    }

    private void on_zoom_out_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_zoom_out_clicked\n" );
        ValaTerminal2.MokoTerminal terminal = (ValaTerminal2.MokoTerminal) notebook.get_nth_page( notebook.get_current_page() );
        terminal.zoom_out();
        update_toolbar();
    }

    private void on_paste_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_paste_clicked\n" );
        ValaTerminal2.MokoTerminal terminal = (ValaTerminal2.MokoTerminal) notebook.get_nth_page( notebook.get_current_page() );
        terminal.paste();
        update_toolbar();
    }

    private void on_prev_tab_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_prev_tab_clicked\n" );
        notebook.prev_page();
        update_toolbar();
    }

    private void on_next_tab_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_next_tab_clicked\n" );
        notebook.next_page();
        update_toolbar();
    }

    private void on_rotate_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_rotate_clicked\n" );
        vertical=!vertical;

        box.remove(notebook);
        box.remove(toolbar);
        remove( box );
        setup_toolbar();

        /* toolbar is top of text / right of text (see .pack_start/.pack_end) */
        if (vertical)
        {
            box = new Gtk.HBox( false, 0 );
            box.pack_start( notebook, true, true, 0 );
            box.pack_start( toolbar, false, false, 0 );
        }
        else 
        {
            box = new Gtk.VBox( false, 0 );
            box.pack_end( notebook, true, true, 0 );
            box.pack_end( toolbar, false, false, 0 );
        }
        add( box );

        /* box.grab_focus(); */  /* this does not help*/
        box.set_focus_child(notebook); /* now this does not work? */
        update_toolbar();
        show_all();
    }

    private void on_fullscreen_clicked( Gtk.ToolButton b )
    {
        stdout.printf( "on_fullscreen_clicked\n" );
        fullscreen_ = !fullscreen_;

        if (fullscreen_)
            this.fullscreen();
        else
            this.unfullscreen();
    }

    public void update_toolbar()
    {
        stdout.printf( "update_toolbar\n" );
        if ( null == notebook )
        {
            stdout.printf( "notebook no longer present\n" );
            return;
        }
        btn_delete.set_sensitive( notebook.get_n_pages() > 1 );
        ValaTerminal2.MokoTerminal terminal = (ValaTerminal2.MokoTerminal) notebook.get_nth_page( notebook.get_current_page() );
        stdout.printf( "current font size for terminal is %u\n", terminal.get_font_size() );
        btn_zoom_in.set_sensitive( terminal.get_font_size() < 20 );
        btn_zoom_out.set_sensitive( terminal.get_font_size() > 1 );

        var current_tab = notebook.get_current_page();
        if (current_tab==-1) /* This in case of error. Do not show error to user */
            current_tab=0;
        current_tab++;       /* Program starts calculating tabs from 0, so we add one to it */

        string count = "tab:%d/%d".printf (current_tab, notebook.get_n_pages());
        btn_prev_tab.set_sensitive( current_tab != 1 );
        btn_next_tab.set_sensitive( current_tab != notebook.get_n_pages() );
        tab_counter.set_label (count);
    }

    public void run()
    {
        // FIXME default focus needs to be on the terminal (in order to play nice with on-screen keyboards)
        show_all();
        Gtk.main();
    }

    const OptionEntry[] options = {
        { "command", 'e', 0, OptionArg.STRING, out initial_command, "Execute COMMAND inside the terminal.", "COMMAND" },
        { "", 'x', 0, OptionArg.STRING_ARRAY, out initial_command_line, "Execute remainder of command line inside the terminal.", "COMMANDS" },
        { null }
    };

    static int main (string[] args) {
      /*FIX. GTK.init_with_args doesn't work. http://bugzilla.gnome.org/show_bug.cgi?id=547135 */
      Gtk.init( ref args );

/*        try {
          Gtk.init_with_args( ref args, " - a lightweight terminal written in Vala", options, "vala-terminal" );
        } catch (Error e)
        {
            stderr.printf("Error: %s\n", e.message);
            return 1;
        }
*/

        uint fontsize = DEFAULT_FONTSIZE;
        bool start_vertical = DEFAULT_START_VERTICAL;
        bool start_fullscreen = false;

        /*commandline parameter handling*/
        int counter=1;
        while (counter<args.length)
        {
            if (args[counter]=="--help") 
            {
               stdout.printf("Flag\tparameter\tmeaning\n");
               stdout.printf(" -v\t        \tStart with toolbar vertically (default=%s)\n",DEFAULT_START_VERTICAL?"vertical":"horizontal");
               stdout.printf(" -h\t        \tStart with toolbar horizontally\n");
               stdout.printf(" --fullscreen\t\tStart fullscreen\n");
               stdout.printf(" -fs\t   int    \tStarting fontize (default=%u)\n",DEFAULT_FONTSIZE);
               stdout.printf(" -f\t fontname \tUses font 'fontname'(default=LiberationMono)\n");
               stdout.printf(" -fc\t  r g b  \tFont color (values are between 0...65535) (default=65535 65535 65535)\n");
               stdout.printf(" -bc\t  r g b  \tBackground color (values are between 0...65535) (default=0 0 0)\n");
               stdout.printf(" -g\t  width height  \tgeometry\n");
               stdout.printf(" -e\tcmd [par1...]\tExecutes 'cmd' inside terminal [with parameters] (-e must be last flag)\n");
               stdout.printf("\n");
               return 0;
            }
            else if (args[counter]=="-e")   /*from xterm  -e command */
            {
               int i=counter+1;
               hack_command="";
               while (args.length>i)
                  {
                  hack_command+=args[i]+" ";
                  i++;
                  }
               hack_command+="\n";
               //stdout.printf( "hack command: '%s'\n",hack_command );
               counter=args.length;
            }
            else if (args[counter]=="-fs") 
            {
               if (counter+2>args.length)
                     {
                     stdout.printf("USAGE: -fs int\n");
                     return 0;
                     }
               fontsize=(args[counter+1]).to_int();
               if (fontsize<1) 
                  fontsize=1;
               counter+=2;
               //stdout.printf("fontsize switched to %u \n",fontsize);
            }
            else if (args[counter]=="-v")
            {
               start_vertical=true;
               counter++;
               //stdout.printf("toolbar switched to vertical\n");
            }
            else if (args[counter]=="-h")
            {
               start_vertical=false;
               counter++;
               //stdout.printf("toolbar switched to horizontal\n");
            }
            else if (args[counter]=="--fullscreen") 
            {
               start_fullscreen=true;
               counter++;
               //stdout.printf("Started with fullscreen\n");
            }
            else if (args[counter]=="-fc")
            {
                if (counter+4>args.length)
                {
                    stdout.printf("USAGE: -fc int int int\n");
                    return 0;
                }
                ValaTerminal2.MokoTerminal.set_fore_color((args[counter+1]).to_int(), (args[counter+2]).to_int(),(args[counter+3]).to_int());
                counter+=4;
                //stdout.printf("foreground color changed\n");
            }
            else if (args[counter]=="-bc")
            {
                if (counter+4>args.length)
                {
                    stdout.printf("USAGE: -bc int int int\n");
                    return 0;
                }
                ValaTerminal2.MokoTerminal.set_back_color((args[counter+1]).to_int(), (args[counter+2]).to_int(),(args[counter+3]).to_int());
                counter+=4;
                //stdout.printf("background color changed\n");
            }
            else if (args[counter]=="-g")
            {
                if (counter+3>args.length)
                {
                    stdout.printf("USAGE: -g X Y\n");
                    return 0;
                }
                MokoTerminal.starting_width = args[counter+1].to_int();
                MokoTerminal.starting_height = args[counter+2].to_int();
                counter+=3;
                //stdout.printf("starting geometry changed\n");
            }
            else if (args[counter]=="-f")
            {
                if (counter+2>args.length)
                {
                    stdout.printf("USAGE: -f fontname\n");
                    return 0;
                }
                ValaTerminal2.MokoTerminal.set_font(args[counter+1]);
                counter+=2;;
               //stdout.printf("font changed\n");
            }
            else
            {
                stdout.printf("%s: unknown flag '%s' \nUse --help\n",args[0],args[counter]);
                return 1;
            }
        }

        ValaTerminal2.MokoTerminal.set_starting_fontsize(fontsize);
        var window = new MainWindow(start_vertical, start_fullscreen);
        if ( initial_command != null )
        {
            window.setup_command( initial_command );
        }
        else if ( initial_command_line != null )
        {
            initial_command = string.joinv( " ", initial_command_line );
            window.setup_command( initial_command );
        }

        window.run();
        return 0;
    }

}
