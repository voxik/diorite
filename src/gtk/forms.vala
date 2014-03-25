/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite
{

public abstract class FormEntry : GLib.Object
{
	public Gtk.Label? label {get; protected set; default = null;}
	public abstract Gtk.Widget widget {get;}
	
	public abstract bool sensitive {get; set; default = true;}
}

public interface ValueEntry: GLib.Object
{
	public abstract Variant value {owned get;}
}

public interface ToggleEntry: GLib.Object
{
	public signal void toggled();
	public abstract bool state {get;}
	public abstract unowned string[] get_enables();
	public abstract unowned string[] get_disables();
}

public class StringEntry : FormEntry, ValueEntry
{
	private Gtk.Entry entry;
	public override Gtk.Widget widget {get{return entry;}}
	public override bool sensitive
	{
		get {return entry.sensitive;}
		set {entry.sensitive = value;}
	}
	
	public Variant value
	{
		owned get
		{
			return new Variant.string(entry.text);
		}
	}
	
	public StringEntry(string? label, string? value)
	{
		if (label != null)
		{
			this.label = new Gtk.Label(label);
			this.label.show();
		}
		
		entry = new Gtk.Entry();
		entry.text = value ?? "";
		entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "edit-clear");
		entry.icon_press.connect(on_icon_press);
		entry.show();
	}
	
	private void on_icon_press(Gtk.EntryIconPosition position, Gdk.Event event)
	{
		if (position == Gtk.EntryIconPosition.SECONDARY)
			entry.set_text("");
	}
}

public class BoolEntry : FormEntry, ToggleEntry
{
	private string[] enables;
	private string[] disables;
	
	private Gtk.CheckButton entry;
	public override Gtk.Widget widget {get{return entry;}}
	
	public override bool sensitive
	{
		get {return entry.sensitive;}
		set {entry.sensitive = value;}
	}
	
	public bool state {get{return entry.active;}}
	
	public BoolEntry(string label, bool value, string[] enables, string[] disables)
	{
		this.enables = enables;
		this.disables = disables;
		entry = new Gtk.CheckButton.with_label(label);
		entry.active = value;
		entry.show();
		entry.toggled.connect(on_toggled);
	}
	
	public unowned string[] get_enables()
	{
		return enables;
	}
	
	public unowned string[] get_disables()
	{
		return disables;
	}
	
	private void on_toggled()
	{
		toggled();
	}
}

public class OptionEntry : FormEntry, ToggleEntry
{
	private string[] enables;
	private string[] disables;
	
	private Gtk.RadioButton entry;
	public override Gtk.Widget widget {get{return entry;}}
	
	public override bool sensitive
	{
		get {return entry.sensitive;}
		set {entry.sensitive = value;}
	}
	
	public bool state {get{return entry.active;}}
	
	public Gtk.RadioButton group
	{
		get
		{
			return entry;
		}
		set
		{
			entry.join_group(value);
		}
	}
	
	public OptionEntry(string label, bool checked, string[] enables, string[] disables)
	{
		this.enables = enables;
		this.disables = disables;
		entry = new Gtk.RadioButton.with_label_from_widget(null, label);
		entry.active = checked;
		entry.show();
		entry.toggled.connect(on_toggled);
	}
	
	public unowned string[] get_enables()
	{
		return enables;
	}
	
	public unowned string[] get_disables()
	{
		return disables;
	}
	
	private void on_toggled()
	{
		toggled();
	}
}

public class Form : Gtk.Grid
{
	private HashTable<string, Variant> values;
	private HashTable<string, FormEntry> entries;
	private HashTable<string, Gtk.RadioButton> radios;
	
	public Form(HashTable<string, Variant> values)
	{
		this.values = values;
		entries = new HashTable<string, FormEntry>(str_hash, str_equal);
		radios = new HashTable<string, Gtk.RadioButton>(str_hash, str_equal);
	}
	
	public Form.from_spec(HashTable<string, Variant> values, Variant entries_spec)
	{
		this(values);
		add_entries(entries_spec);
	}
	
	public void add_entries(Variant entries_spec)
	{
		var array = variant_to_array(entries_spec);
		foreach (unowned Variant entry_spec in array)
			add_entry(variant_to_array(entry_spec));
	}
	
	public void add_values(HashTable<string, Variant> values)
	{
		foreach (var key in values.get_keys())
			this.values.replace(key, values.get(key));
	}
	
	public void add_entry(Variant[] entry_spec)
	{
		weak Gtk.Label label = null;
		weak Gtk.Widget widget = null;
		string type = entry_spec[0].get_string();
		switch (type)
		{
		case "string":
			var id = entry_spec[1].get_string();
			string? e_label = null;
			if (entry_spec.length >= 3 && entry_spec[2].is_of_type(VariantType.STRING))
				e_label = entry_spec[2].get_string();
			string? e_value = null;
			var value = values.get(id);
			if (value != null && value.is_of_type(VariantType.STRING))
				e_value = value.get_string();
			var entry = new StringEntry(e_label, e_value);
			label = entry.label;
			widget = entry.widget;
			entries.set(id, entry);
			break;
		case "bool":
			var id = entry_spec[1].get_string();
			string e_label = entry_spec[2].get_string();
			bool e_value = false;
			var value = values.get(id);
			if (value != null && value.is_of_type(VariantType.BOOLEAN))
				e_value = value.get_boolean();
			string[] e_enables;
			if (entry_spec.length > 3)
				e_enables = variant_to_strv(entry_spec[3]);
			else
				e_enables = {};
			string[] e_disables;
			if (entry_spec.length > 4)
				e_disables = variant_to_strv(entry_spec[4]);
			else
				e_disables = {};
			var entry = new Diorite.BoolEntry(e_label, e_value, e_enables, e_disables);
			entry.toggled.connect(on_entry_toggled);
			label = entry.label;
			widget = entry.widget;
			entries.set(id, entry);
			break;
		case "option":
			var full_id = entry_spec[1].get_string();
			var i = full_id.index_of(":");
			return_if_fail(i > 0);
			var id = full_id.substring(0, i);
			var e_target = full_id.substring(i + 1);
			string e_label = entry_spec[2].get_string();
			var value = values.get(id);
			bool e_checked = value.is_of_type(VariantType.STRING) && value.get_string() == e_target;
			string[] e_enables;
			if (entry_spec.length > 3)
				e_enables = variant_to_strv(entry_spec[3]);
			else
				e_enables = {};
			string[] e_disables;
			if (entry_spec.length > 4)
				e_disables = variant_to_strv(entry_spec[4]);
			else
				e_disables = {};
			var entry = new Diorite.OptionEntry(e_label, e_checked, e_enables, e_disables);
			entry.toggled.connect(on_entry_toggled);
			label = entry.label;
			widget = entry.widget;
			entries.set(full_id, entry);
			var group = radios.get(id);
			if (group == null)
				radios.set(id, entry.group);
			else
				entry.group = group;
			break;
		default:
			warning("Unsupported type: %s", type);
			return;
		}
		
		if (label != null)
		{
			attach_next_to(label, null, Gtk.PositionType.BOTTOM, 1, 1);
			label.margin_left = 8;
			label.margin_top = 5;
			label.show();
			attach_next_to(widget, label, Gtk.PositionType.RIGHT, 1, 1);
		}
		else
		{
			attach_next_to(widget, null, Gtk.PositionType.BOTTOM, 2, 1);
		}
		widget.margin_left = 8;
		widget.margin_right = 8;
		widget.margin_top = 5;
		widget.show();
	}
	
	public void check_toggles()
	{
		var entries = this.entries.get_values();
		foreach (var entry in entries)
		{
			var toggle = entry as Diorite.ToggleEntry;
			if (toggle != null)
				entry_toggled(toggle);
		}
	}
	
	public HashTable<string, Variant> get_original_values()
	{
		return values;
	}
	
	public HashTable<string, Variant> get_values()
	{
		var result = new HashTable<string, Variant>(str_hash, str_equal);
		foreach (var key in entries.get_keys())
		{
			var entry = entries.get(key);
			var value_entry = entry as ValueEntry;
			var toggle_entry = entry as ToggleEntry;
			if (value_entry != null)
			{
				result.insert(key, value_entry.value);
			}
			else if (toggle_entry != null)
			{
				if (toggle_entry is BoolEntry)
				{
					result.insert(key, new Variant.boolean(toggle_entry.state));
				}
				else if (toggle_entry is OptionEntry && toggle_entry.state)
				{
					var i = key.index_of(":");
					if (i > 0)
						result.insert(key.substring(0, i), new Variant.string(key.substring(i + 1)));
				}
			}
		}
		
		return result;
	}
	
	private void entry_toggled(ToggleEntry entry)
	{
		var state = entry.state;
		foreach (var key in entry.get_enables())
		{
			var target = entries.get(key);
			if (target != null)
				target.sensitive = state;
		}
		foreach (var key in entry.get_disables())
		{
			var target = entries.get(key);
			if (target != null)
				target.sensitive = !state;
		}
	}
	
	private void on_entry_toggled(ToggleEntry entry)
	{
		entry_toggled(entry);
	}
}

} // namespace Diorite
