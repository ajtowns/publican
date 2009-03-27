import gedit
import gtk

import os
from xml.dom import minidom
ui_str = """<ui>
  <menubar name="MenuBar">
    <menu name="Publican" action="PublicanMenuAction">
        <menuitem name="OpenDocument" action="OpenDocument"/>
        <menuitem name="CreateDocument" action="CreateDocument"/>
        <menu name="PublicanMenuTools" action="PublicanMenuTools">
            <menuitem name="xiincludetool" action="xiincludetool"/>
        </menu>
    </menu>
  </menubar>
</ui>
"""

class ResultsView(gtk.VBox):
    def __init__(self, geditwindow, path):
        def fileExists(f):
            try:
                file = open(f)
            except IOError:
                exists = 0
            else:
                exists = 1
            return exists

        def traverseDocument(myfilename, level):
            if fileExists(path+myfilename):
                doc = minidom.parse(path+myfilename)
                xi_list = doc.getElementsByTagName('xi:include')
                for x in xi_list[:]:
                    if fileExists(path+x.attributes["href"].value):
                        mylevel = self.treestore.append(level, ["0", x.attributes["href"].value, gtk.Window().render_icon(gtk.STOCK_FILE, gtk.ICON_SIZE_MENU)])
                        if x.attributes["href"].value.rpartition('.')[2] == 'xml':
                            traverseDocument(x.attributes["href"].value, mylevel)
                    else:
                        mylevel = self.treestore.append(level, ["-1",x.attributes["href"].value, gtk.Window().render_icon(gtk.STOCK_DIALOG_WARNING, gtk.ICON_SIZE_MENU)])

        gtk.VBox.__init__(self)
        self.language_manager = gedit.get_language_manager()
        self.DEFAULT_LANG = 'en-US'
        self.thepath = ""
        self.geditwindow = geditwindow
        try: self.encoding = gedit.encoding_get_current()
        except: self.encoding = gedit.gedit_encoding_get_current()
        self.open_files = []
        self.treestore = gtk.TreeStore(str,str,gtk.gdk.Pixbuf)
        self.treeview = gtk.TreeView(self.treestore)
        self.treeview.connect("row-activated", self.open_file)
        self.geditwindow.connect("tab-removed", self.tab_closed)
        self.geditwindow.connect("active-tab-changed", self.tab_changed)
        tree_selection = self.treeview.get_selection()
        tree_selection.set_mode(gtk.SELECTION_SINGLE)
        tree_selection.connect("changed", self.switch_to_file)
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
            traverseDocument(xa.attributes["href"].value, mylevela)
        
        

    def open_file(self, widget, a, b):
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
            buffer = self.geditwindow.get_active_view().get_buffer()
            language = gedit.language_manager_get_language_from_mime_type(self.language_manager, "application/docbook+xml")
            buffer.set_language(language)

    def switch_to_file(self, widget):
        tree_selection = self.treeview.get_selection()
        (model, iterator) = tree_selection.get_selected()
        if (model.get_value(iterator, 0) == "1"):
            documents = self.geditwindow.get_documents()
            for each in documents:
                if each.get_uri_for_display().rpartition('/'+self.DEFAULT_LANG+'/')[2] == model.get_value(iterator, 1):
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

class PluginHelper:
    def __init__(self, plugin, window):
        self.window = window
        self.plugin = plugin
        self.ui_id = None
        self.language_manager = gedit.get_language_manager()

        #insert the menu items
        manager = self.window.get_ui_manager()
        self._action_group = gtk.ActionGroup("ExamplePyPluginActions")
        self._action_group.add_actions([("OpenDocument", None, _("Open Document"), None, _("Open an Existing Publican Document"), self.on_open_document_activate)])
        self._action_group.add_actions([("CreateDocument", None, _("Create New Document"), None, _("Create a new publican document"), self.on_create_document_activate)])
        self._action_group.add_actions([("PublicanMenuAction", None, _("Publican"), None, _("Clear the document"), None)])
        self._action_group.add_actions([("PublicanMenuTools", None, _("Tools"), None, _("Clear the document"), None)])
        self._action_group.add_actions([("xiincludetool", None, _("xi:include"), "<control><shift>x", _("Clear the document"), self.xiinclude_tool)])
        manager.insert_action_group(self._action_group, -1)
        self._ui_id = manager.add_ui_from_string(ui_str)

    def deactivate(self):        
        self.remove_panel()
        self.window = None
        self.plugin = None
        
    def update_ui(self):
        pass
        
    def remove_panel(self):
        panel = self.window.get_side_panel()
        panel.remove_item(self.results_view)
    
    def on_create_document_activate(self, action):
        dialog = gtk.Dialog("My dialog", None, gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT, (gtk.STOCK_CANCEL, gtk.RESPONSE_REJECT, gtk.STOCK_OK, gtk.RESPONSE_ACCEPT))
        label = gtk.Label("Implement Create Book Dialog Here...")
        box = dialog.vbox
        box.add(label)
        box.show_all()
        dialog.run()
        dialog.destroy()
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
    def xiinclude_tool(self, action):
        doc = self.window.get_active_document()
        
        if not doc:
            return
        text = doc.get_text(doc.get_selection_bounds()[0], doc.get_selection_bounds()[1], False)
        filepath = doc.get_uri_for_display().rpartition("/")[0]
        dialog = gtk.Dialog("My dialog", None, gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT, (gtk.STOCK_CANCEL, gtk.RESPONSE_REJECT, gtk.STOCK_OK, gtk.RESPONSE_ACCEPT))
        dialog.set_default_response(gtk.RESPONSE_ACCEPT)
        entry = gtk.Entry()
        entry.set_activates_default(True)
        box = dialog.vbox
        box.add(entry)
        box.show_all()
        response = dialog.run()
        thefilename = entry.get_text()
        if response == gtk.RESPONSE_ACCEPT:
            node = minidom.parseString(text)
            f = open(filepath+'/'+thefilename,'w')
            f.write("<?xml version='1.0'?>\n")
            f.write("<!DOCTYPE "+node.documentElement.tagName+" PUBLIC \"-//OASIS//DTD DocBook XML V4.5//EN\" \"http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd\" [\n")
            f.write("]>\n\n")
            f.write(text)
            f.close()
            self.window.create_tab_from_uri("file://"+filepath+'/'+thefilename, None, 1, False, True)
            doc.delete_selection(True, True)
            doc.insert_at_cursor("<xi:include href=\""+thefilename+"\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />")
        
            buffer = self.window.get_active_view().get_buffer()
            language = gedit.language_manager_get_language_from_mime_type(self.language_manager, "application/docbook+xml")
            buffer.set_language(language)
        dialog.destroy()

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
