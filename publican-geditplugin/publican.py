import gedit
import gtk

import os
from xml.dom import minidom
ui_str = """<ui>
  <menubar name="MenuBar">
    <menu name="Publican" action="PublicanMenuAction">
        <menuitem name="ExamplePy" action="ExamplePy"/>
    </menu>
  </menubar>
</ui>
"""
class ResultsView(gtk.VBox):
    def __init__(self, geditwindow, path):
        gtk.VBox.__init__(self)
        
        self.DEFAULT_LANG = 'en-US'
        


        self.thepath = ""
        self.geditwindow = geditwindow
        self.renderer = gtk.CellRendererText()
        self.renderer.weight = 600
        try: self.encoding = gedit.encoding_get_current()
        except: self.encoding = gedit.gedit_encoding_get_current()
        self.open_files = []
        self.treestore = gtk.TreeStore(str,str,gtk.gdk.Pixbuf)
        

        self.treeview = gtk.TreeView(self.treestore)
        self.treeview.connect("row-activated", self.view_result)
        self.geditwindow.connect("tab-removed", self.tab_closed)
        self.geditwindow.connect("active-tab-changed", self.tab_changed)
        tree_selection = self.treeview.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.view_result2)
        self.cell = gtk.CellRendererText()
        self.tvcolumn = gtk.TreeViewColumn('Files')

        render_pixbuf = gtk.CellRendererPixbuf()
        self.tvcolumn.pack_start(render_pixbuf, expand=False)
        self.tvcolumn.add_attribute(render_pixbuf, 'pixbuf', 2)
        
        self.tvcolumn.pack_start(self.cell, expand=True)
        self.tvcolumn.add_attribute(self.cell, 'text', 1)
        
        self.treeview.append_column(self.tvcolumn)
        self.tvcolumn.set_sort_column_id(0)
        self.treeview.set_search_column(1)
        
        self.treeview.set_reorderable(False)
        scrolled_window = gtk.ScrolledWindow()        
        scrolled_window.add(self.treeview)
        self.pack_start(scrolled_window)
        self.show_all()
        def fileExists(f):
            try:
                file = open(f)
            except IOError:
                exists = 0
            else:
                exists = 1
            return exists

        def pants(myfilename, level):
            if fileExists(path+myfilename):
                doc = minidom.parse(path+myfilename)
                xi_list = doc.getElementsByTagName('xi:include')
                for x in xi_list[:]:
                    if fileExists(path+x.attributes["href"].value):
                        mylevel = self.treestore.append(level, ["0", x.attributes["href"].value, gtk.Window().render_icon(gtk.STOCK_FILE, gtk.ICON_SIZE_MENU)])
                        if x.attributes["href"].value.rpartition('.')[2] == 'xml':
                            pants(x.attributes["href"].value, mylevel)
                    else:
                        mylevel = self.treestore.append(level, ["-1",x.attributes["href"].value, gtk.Window().render_icon(gtk.STOCK_DIALOG_WARNING, gtk.ICON_SIZE_MENU)])
        
        #filename = 'samplebook.xml'
        filename = path.rpartition('/')[2]+'.xml'
        bookpath = path
        path = path+'/'+self.DEFAULT_LANG+'/'
        self.thepath = path
        self.treestore.clear()
        self.open_files = []
        xmldoc = minidom.parse(path+filename)
        level = self.treestore.append(None, ["0",filename, gtk.Window().render_icon(gtk.STOCK_FILE, gtk.ICON_SIZE_MENU)])
        xi_lista = xmldoc.getElementsByTagName('xi:include')
        for xa in xi_lista[:]:
            mylevela = self.treestore.append(level, ["0",xa.attributes["href"].value, gtk.Window().render_icon(gtk.STOCK_FILE, gtk.ICON_SIZE_MENU)])
            pants(xa.attributes["href"].value, mylevela)
        
        

    def view_result(self, widget, a, b):
        tree_selection = self.treeview.get_selection()
        (model, iterator) = tree_selection.get_selected()
        absolute_path = model.get_value(iterator, 1)
        if (model.get_value(iterator, 0) == "1"):
            documents = self.geditwindow.get_documents()
            for each in documents:
                if each.get_short_name_for_display() == model.get_value(iterator, 1):
                    self.geditwindow.set_active_tab(gedit.tab_get_from_document(each))
        elif (model.get_value(iterator, 0) == "-1"):
            None
        else:
            self.geditwindow.create_tab_from_uri("file://"+self.thepath+absolute_path, None, 1, False, True)
            self.treestore.set_value(iterator, 0, "1")
            self.treestore.set_value(iterator, 2, gtk.Window().render_icon(gtk.STOCK_EDIT, gtk.ICON_SIZE_MENU))
            self.open_files.append(iterator)
            #self.treeview.get_column(1).set_cell_data
    def view_result2(self, widget):
        tree_selection = self.treeview.get_selection()
        (model, iterator) = tree_selection.get_selected()
        if (model.get_value(iterator, 0) == "1"):
            documents = self.geditwindow.get_documents()
            for each in documents:
                if each.get_short_name_for_display() == model.get_value(iterator, 1):
                    self.geditwindow.set_active_tab(gedit.tab_get_from_document(each))
        
    def tab_closed(self, b, tab):
        model = self.treeview.get_model()
        for s in self.open_files:
            filename = tab.get_document().get_uri_for_display().rpartition('/'+self.DEFAULT_LANG+'/')[2]
            if (model.get_value(s, 1) == filename):
                model.set_value(s, 0, "0")
                model.set_value(s, 2, gtk.Window().render_icon(gtk.STOCK_FILE, gtk.ICON_SIZE_MENU))
                self.open_files.remove(s)
    
    def tab_changed(self, b, tab):
        model = self.treeview.get_model()
        tree_selection = self.treeview.get_selection()
        for s in self.open_files:
            filename = tab.get_document().get_uri_for_display().rpartition('/'+self.DEFAULT_LANG+'/')[2]
            if (model.get_value(s, 1) == filename):
                tree_selection.select_iter(s)      

#class Publican_Tab(gtk.VBox):
#    def __init__(self, geditwindow):
#        gtk.VBox.__init__(self)
#        self.geditwindow = geditwindow
#        button_open = gtk.Button("Open Document")
#        button_open.connect("clicked", self.open_document)
#        search_box = gtk.HBox(False, 0)
#        search_box.pack_start(button_open, False, False)
#        self.pack_start(search_box, False, False)
#        self.show_all()
#    def open_document(self, widget):
#        panel = self.geditwindow.get_side_panel()
#        self.results_view = ResultsView(self.geditwindow)
#        image = gtk.Image()
#        image.set_from_stock(gtk.STOCK_DND_MULTIPLE, gtk.ICON_SIZE_BUTTON)
#        self.ui_id = panel.add_item(self.results_view, "Publican Document View", image)
#        panel.activate_item(self.results_view)
class PluginHelper:
    def __init__(self, plugin, window):
        self.window = window
        self.plugin = plugin
        
        self.ui_id = None
        
        #self.add_panel(window)
        self._insert_menu()

    def deactivate(self):        
        self.remove_panel()
        
        self.window = None
        self.plugin = None
        
    def update_ui(self):
        pass
        
    #def add_panel(self, window):
    #    panel = self.window.get_side_panel()
    #    self.publican_tab = Publican_Tab(window)
    #    image2 = gtk.Image()
    #    image2.set_from_stock(gtk.STOCK_COPY, gtk.ICON_SIZE_BUTTON)
    #    self.ui_id = panel.add_item(self.publican_tab, "Publican", image2)
        
    def remove_panel(self):
        panel = self.window.get_side_panel()
        panel.remove_item(self.results_view)
    
    def _insert_menu(self):
        manager = self.window.get_ui_manager()
        self._action_group = gtk.ActionGroup("ExamplePyPluginActions")
        self._action_group.add_actions([("ExamplePy", None, _("Open Document"),
                                         None, _("Open an Existing Publican Document"),
                                         self.on_open_document_activate)])
        self._action_group.add_actions([("PublicanMenuAction", None, _("Publican"),
                                         None, _("Clear the document"),
                                         None)])
        manager.insert_action_group(self._action_group, -1)
        self._ui_id = manager.add_ui_from_string(ui_str)
    
    def on_open_document_activate(self, action):
        panel = self.window.get_side_panel()
        
        dialog = gtk.FileChooserDialog("Open..", None, gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER, (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,gtk.STOCK_OPEN, gtk.RESPONSE_OK)) 
        dialog.set_default_response(gtk.RESPONSE_OK)
        response = dialog.run()
        path = dialog.get_filename()
        dialog.destroy()
        self.results_view = ResultsView(self.window, path)
        image = gtk.Image()
        image.set_from_stock(gtk.STOCK_DND_MULTIPLE, gtk.ICON_SIZE_BUTTON)
        self.ui_id = panel.add_item(self.results_view, "Publican Document View", image)
        panel.activate_item(self.results_view)


class PublicanPlugin(gedit.Plugin):
    def __init__(self):
        gedit.Plugin.__init__(self)
        self.instances = {}
        
    def activate(self, window):
        self.instances[window] = PluginHelper(self, window)
        
    def deactivate(self, window):
        self.instances[window].deactivate()
        
    def update_ui(self, window):
        self.instances[window].update_ui()
