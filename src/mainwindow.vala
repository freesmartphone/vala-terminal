/*
 * mainwindow.vala
 *
 * Authored by Michael 'Mickey' Lauer <mickey@vanille-media.de>
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
 *
 * Contributions by Aapo Rantalainen:
 * - rotatable toolbar
 * - no tab-panel (tab are changed by toolbar)
 * - increased fontsize max 
 * - start with focus on textarea
 * - (workaround of commandlinebug)
 *
 * - Jump to the new created tab
 */

using GLib;
using Gtk;

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
    private ToolButton btn_rotate;
    private ToolButton tab_counter;

    private static string initial_command;
    private static string[] initial_command_line;
    private bool vertical;  /* true, if toolbar is oriented vertically */

    /* because of bug http://bugzilla.gnome.org/show_bug.cgi?id=547135,
    we just pass whole commandline to the terminal */
    private static string hack_command;

    public MainWindow()
    {
        title = "Terminal";
    }

    construct
    {
        destroy += Gtk.main_quit;
        vertical=false;

        if (vertical)
            box = new Gtk.HBox( false, 0 );
        else
            box = new Gtk.VBox( false, 0 );
        add( box );

        setup_toolbar();
        box.pack_start( toolbar, false, false, 0 );

        setup_notebook();
        box.pack_start( notebook, true, true, 0 );

        box.set_focus_child(notebook);

        notebook.page_removed += (o, page, num) => {
            stdout.printf( "on_page_removed\n");
            if ( notebook.get_n_pages() == 0 )
                Gtk.main_quit();
            else
                update_toolbar();
        };

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

        tab_counter = new ToolButton(null, "");
        toolbar.pack_start( tab_counter, false, false, 0 );

        //toolbar.insert( new Gtk.SeparatorToolItem(), 11 );

        btn_rotate = new Gtk.ToolButton.from_stock( STOCK_REFRESH );
        btn_rotate.clicked += on_rotate_clicked;
        btn_rotate.set_label ("Rotate");
        toolbar.pack_start( btn_rotate, false, false, 0 );
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
        try {
         // Gtk.init_with_args( ref args, " - a lightweight terminal written in Vala", options, "vala-terminal" );
            Gtk.init( ref args ); /*FIX. GTK-args do not work*/
        } catch (Error e)
        {
            stderr.printf("Error: %s\n", e.message);
            return 1;
        }

        if (args.length>1)
         {
         // just pass all parameters (see: http://bugzilla.gnome.org/show_bug.cgi?id=547135 )
         if (args[1]=="-e")
            {
            int i=2;
            hack_command="";
            while (args.length>i)
               {
               hack_command+=args[i]+" ";
               i++;
               }
            hack_command+="\n";
            //stdout.printf( "hack command: '%s'\n",hack_command );
            }
         else
            {
            stdout.printf("%s: unknown flag '%s' \n",args[0],args[1]);
            return 1;
            }
         }

        var window = new MainWindow();
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
