class DsfrFormBuilder < ActionView::Helpers::FormBuilder
  def dsfr_text_field(attribute, opts = {}, &)
    dsfr_input_field(attribute, :text_field, opts, &)
  end

  def dsfr_text_area(attribute, opts = {}, &)
    value = @object.public_send(attribute)
    text = Array(value).join("\n")
    dsfr_input_field(attribute, :text_area, { value: (text if value.is_a?(Array)), rows: rows_for(text) }.compact.merge(opts), &)
  end

  def dsfr_number_field(attribute, opts = {}, &)
    dsfr_input_field(attribute, :number_field, opts, &)
  end

  def dsfr_file_field(attribute, opts = {}, &)
    dsfr_field_group(attribute, opts, 'fr-upload-group', file_field(attribute, class: 'fr-upload', **input_options(attribute, opts)), &)
  end

  def dsfr_check_box(attribute, opts = {})
    dsfr_input_group(attribute, opts) do
      @template.content_tag(:div, class: 'fr-checkbox-group') do
        @template.safe_join([check_box(attribute, input_options(attribute, opts)), label_with_hint(attribute), error_message(attribute)].compact)
      end
    end
  end

  def dsfr_select(attribute, choices, opts = {}, &)
    select_tag = select(attribute, choices, { include_blank: true }, class: 'fr-select', **input_options(attribute, opts))
    dsfr_field_group(attribute, opts, 'fr-select-group', select_tag, &)
  end

  def field_id_for_error(attribute)
    field_id(field_of_error(attribute))
  end

  private

  def dsfr_input_group(attribute, opts, group_class = 'fr-input-group', &)
    classes = [group_class, ("#{group_class}--error" if errors_for(attribute).any?), opts[:class]].compact.join(' ')
    @template.content_tag(:div, { class: classes }.merge(opts[:input_group_options] || {}), &)
  end

  def dsfr_input_field(attribute, input_kind, opts, &)
    dsfr_field_group(attribute, opts, 'fr-input-group', public_send(input_kind, attribute, class: 'fr-input', **input_options(attribute, opts)), &)
  end

  def dsfr_field_group(attribute, opts, group_class, input, &block)
    dsfr_input_group(attribute, opts, group_class) do
      @template.safe_join([label_with_hint(attribute), input, (@template.capture(&block) if block), error_message(attribute)].compact)
    end
  end

  def label_with_hint(attribute)
    label(attribute, class: 'fr-label') do |text|
      @template.safe_join([required?(attribute) ? "#{text.translation} (obligatoire)" : text.translation, hint(attribute)].compact)
    end
  end

  def hint(attribute)
    text = I18n.t("activerecord.hints.#{@object.model_name.i18n_key}.#{attribute}", default: nil)
    @template.content_tag(:span, text, class: 'fr-hint-text') if text
  end

  def error_message(attribute)
    messages = errors_for(attribute)
    return if messages.none?

    @template.content_tag(:div, id: messages_id(attribute), class: 'fr-messages-group', aria: { live: 'polite' }) do
      @template.safe_join(messages.map { |message| @template.content_tag(:p, message, class: 'fr-message fr-message--error') })
    end
  end

  def input_options(attribute, opts)
    aria = errors_for(attribute).any? ? { aria: { invalid: true, describedby: messages_id(attribute) } } : {}
    opts.except(:class, :input_group_options).merge(required: required?(attribute), **aria)
  end

  def messages_id(attribute) = "#{field_id(attribute)}-messages"

  def errors_for(attribute)
    @object.errors.select { |error| field_of_error(error.attribute) == attribute.to_s }.map(&:full_message)
  end

  def field_of_error(attribute) = (@object.class.reflect_on_association(attribute)&.foreign_key || attribute).to_s

  def required?(attribute)
    association = @object.class.reflect_on_all_associations(:belongs_to).find { |reflection| reflection.foreign_key == attribute.to_s }
    association ? !association.options[:optional] : always_present?(attribute)
  end

  def always_present?(attribute)
    @object.class.validators_on(attribute).any? { |validator| validator.kind == :presence && validator.options.slice(:if, :unless, :on).empty? }
  end

  def rows_for(text)
    lines = text.lines.sum { |line| [(line.chomp.length / 80.0).ceil, 1].max }
    [lines + 2, 6].max
  end
end
