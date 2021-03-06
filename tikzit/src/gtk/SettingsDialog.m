/*
 * Copyright 2012  Alex Merry <dev@randomguy3.me.uk>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "SettingsDialog.h"

#import "Application.h"
#import "Configuration.h"
#import "EdgeStylesPalette.h"
#import "NodeStylesPalette.h"
#import "StyleManager.h"

// {{{ Internal interfaces
// {{{ Signals
static gboolean window_delete_event_cb (GtkWidget *widget,
                                        GdkEvent  *event,
                                        SettingsDialog *dialog);
static void ok_button_clicked_cb (GtkButton *widget, SettingsDialog *dialog);
static void cancel_button_clicked_cb (GtkButton *widget, SettingsDialog *dialog);
// }}}

@interface SettingsDialog (Private)
- (void) loadUi;
- (void) save;
- (void) revert;
@end

// }}}
// {{{ API

@implementation SettingsDialog

- (id) init {
    [self release];
    return nil;
}

- (id) initWithConfiguration:(Configuration*)c andStyleManager:(StyleManager*)m {
    self = [super init];

    if (self) {
        configuration = [c retain];
        styleManager = [m retain];
        tempStyleManager = [m copy];
    }

    return self;
}

- (void) dealloc {
    if (window) {
        gtk_widget_destroy (GTK_WIDGET (window));
    }
    if (parentWindow) {
        g_object_unref (parentWindow);
    }

    [configuration release];
    [tempStyleManager release];
    [styleManager release];
    [nodePalette release];
    [edgePalette release];

    [super dealloc];
}

- (Configuration*) configuration {
    return configuration;
}

- (void) setConfiguration:(Configuration*)c {
    [c retain];
    [configuration release];
    configuration = c;
    [self revert];
}

- (StyleManager*) styleManager {
    return styleManager;
}

- (void) setStyleManager:(StyleManager*)m {
    [m retain];
    [styleManager release];
    styleManager = m;
}

- (GtkWindow*) parentWindow {
    return parentWindow;
}

- (void) setParentWindow:(GtkWindow*)parent {
    GtkWindow *oldParent = parentWindow;

    if (parent)
        g_object_ref (parent);
    parentWindow = parent;
    if (oldParent)
        g_object_unref (oldParent);

    if (window) {
        gtk_window_set_transient_for (window, parentWindow);
    }
}

- (void) present {
    [self loadUi];
    [self revert];
    gtk_window_present (GTK_WINDOW (window));
}

- (void) show {
    [self loadUi];
    [self revert];
    gtk_widget_show (GTK_WIDGET (window));
}

- (void) hide {
    if (!window) {
        return;
    }
    gtk_widget_hide (GTK_WIDGET (window));
}

- (BOOL) isVisible {
    if (!window) {
        return NO;
    }
    gboolean visible;
    g_object_get (G_OBJECT (window), "visible", &visible, NULL);
    return visible ? YES : NO;
}

- (void) setVisible:(BOOL)visible {
    if (visible) {
        [self show];
    } else {
        [self hide];
    }
}

@end

// }}}
// {{{ Private

@implementation SettingsDialog (Private)
- (void) loadUi {
    if (window) {
        return;
    }

    nodePalette = [[NodeStylesPalette alloc] initWithManager:tempStyleManager];
    edgePalette = [[EdgeStylesPalette alloc] initWithManager:tempStyleManager];

    window = GTK_WINDOW (gtk_window_new (GTK_WINDOW_TOPLEVEL));
    gtk_window_set_default_size (window, 570, -1);
    gtk_window_set_title (window, "TikZiT Configuration");
    gtk_window_set_modal (window, TRUE);
    gtk_window_set_position (window, GTK_WIN_POS_CENTER_ON_PARENT);
    gtk_window_set_type_hint (window, GDK_WINDOW_TYPE_HINT_DIALOG);
    if (parentWindow) {
        gtk_window_set_transient_for (window, parentWindow);
    }
    g_signal_connect (window,
                      "delete-event",
                      G_CALLBACK (window_delete_event_cb),
                      self);

    GtkWidget *mainBox = gtk_vbox_new (FALSE, 18);
    gtk_container_set_border_width (GTK_CONTAINER (mainBox), 12);
    gtk_container_add (GTK_CONTAINER (window), mainBox);
    gtk_widget_show (mainBox);

#ifdef HAVE_POPPLER
    /*
     * Path for pdflatex
     */

    GtkWidget *pdflatexFrame = gtk_frame_new ("Previews");
    gtk_box_pack_start (GTK_BOX (mainBox), pdflatexFrame, TRUE, TRUE, 0);

    GtkBox *pdflatexBox = GTK_BOX (gtk_hbox_new (FALSE, 6));
    gtk_container_add (GTK_CONTAINER (pdflatexFrame), GTK_WIDGET (pdflatexBox));
    gtk_container_set_border_width (GTK_CONTAINER (pdflatexBox), 6);

    GtkWidget *pdflatexLabel = gtk_label_new ("Path to pdflatex:");
    gtk_misc_set_alignment (GTK_MISC (pdflatexLabel), 0, 0.5);
    gtk_box_pack_start (pdflatexBox,
                        pdflatexLabel,
                        FALSE, TRUE, 0);

    pdflatexPathEntry = GTK_ENTRY (gtk_entry_new ());
    gtk_box_pack_start (pdflatexBox,
                        GTK_WIDGET (pdflatexPathEntry),
                        TRUE, TRUE, 0);

    gtk_widget_show_all (pdflatexFrame);
#else
    pdflatexPathEntry = NULL;
#endif

    /*
     * Node styles
     */
    GtkWidget *nodeStylesFrame = gtk_frame_new ("Node Styles");
    gtk_widget_show (nodeStylesFrame);
    gtk_box_pack_start (GTK_BOX (mainBox), nodeStylesFrame, TRUE, TRUE, 0);
    gtk_container_add (GTK_CONTAINER (nodeStylesFrame),
            GTK_WIDGET ([nodePalette widget]));
    gtk_widget_show ([nodePalette widget]);


    /*
     * Edge styles
     */
    GtkWidget *edgeStylesFrame = gtk_frame_new ("Edge Styles");
    gtk_widget_show (edgeStylesFrame);
    gtk_box_pack_start (GTK_BOX (mainBox), edgeStylesFrame, TRUE, TRUE, 0);
    gtk_container_add (GTK_CONTAINER (edgeStylesFrame),
            GTK_WIDGET ([edgePalette widget]));
    gtk_widget_show ([edgePalette widget]);


    /*
     * Bottom buttons
     */

    GtkContainer *buttonBox = GTK_CONTAINER (gtk_hbutton_box_new ());
    gtk_box_set_spacing (GTK_BOX (buttonBox), 6);
    gtk_button_box_set_layout (GTK_BUTTON_BOX (buttonBox), GTK_BUTTONBOX_END);
    gtk_box_pack_start (GTK_BOX (mainBox),
                        GTK_WIDGET (buttonBox),
                        FALSE, TRUE, 0);

    GtkWidget *okButton = gtk_button_new_from_stock (GTK_STOCK_OK);
    gtk_container_add (buttonBox, okButton);
    g_signal_connect (okButton,
                      "clicked",
                      G_CALLBACK (ok_button_clicked_cb),
                      self);

    GtkWidget *cancelButton = gtk_button_new_from_stock (GTK_STOCK_CANCEL);
    gtk_container_add (buttonBox, cancelButton);
    g_signal_connect (cancelButton,
                      "clicked",
                      G_CALLBACK (cancel_button_clicked_cb),
                      self);

    gtk_widget_show_all (GTK_WIDGET (buttonBox));

    [self revert];
}

- (void) save {
    if (!window)
        return;

#ifdef HAVE_POPPLER
    const gchar *path = gtk_entry_get_text (pdflatexPathEntry);
    if (path && *path) {
        [configuration setStringEntry:@"pdflatex"
                              inGroup:@"Previews"
                                value:[NSString stringWithUTF8String:path]];
    }
#endif

    [styleManager updateFromManager:tempStyleManager];

    [app saveConfiguration];
}

- (void) revert {
    if (!window)
        return;

#ifdef HAVE_POPPLER
    NSString *path = [configuration stringEntry:@"pdflatex"
                                        inGroup:@"Previews"
                                    withDefault:@"pdflatex"];
    gtk_entry_set_text (pdflatexPathEntry, [path UTF8String]);
#endif

    [tempStyleManager updateFromManager:styleManager];
}
@end

// }}}
// {{{ GTK+ callbacks

static gboolean window_delete_event_cb (GtkWidget *widget,
                                        GdkEvent  *event,
                                        SettingsDialog *dialog) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [dialog hide];
    [pool drain];
    return TRUE; // we dealt with this event
}

static void ok_button_clicked_cb (GtkButton *widget, SettingsDialog *dialog) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [dialog save];
    [dialog hide];
    [pool drain];
}

static void cancel_button_clicked_cb (GtkButton *widget, SettingsDialog *dialog) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [dialog hide];
    [pool drain];
}

// }}}

// vim:ft=objc:ts=4:et:sts=4:sw=4:foldmethod=marker
