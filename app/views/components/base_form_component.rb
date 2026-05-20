class BaseFormComponent < ApplicationViewComponent
  option :name
  option :id, optional: true, default: proc { nil }
  option :data, optional: true, default: proc { {} }
  option :form, optional: true, default: proc { nil }
  option :value, optional: true
  option :record, optional: true, default: proc { nil }
  option :label_text, optional: true, default: proc { nil }
  option :placeholder, optional: true, default: proc { "" }
  option :required, optional: true, default: proc { false }
  option :class_names, optional: true, default: proc { nil }
  option :helper_text, optional: true, default: proc { nil }
  option :autofocus, optional: true, default: proc { false }
  option :autocomplete, optional: true, default: proc { nil }
  option :field_type, optional: true, default: proc { :text_field }

  def errors
    errs = @form&.object&.errors

    return "" if errs.blank?

    @errors ||= errs.[](@name)&.join(", ")&.humanize
  end

  def errors?
    !errors.empty?
  end
end
