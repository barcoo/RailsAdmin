# frozen_string_literal: true
module Kadmin
  # Parsing is done by using attribute setters. If you have an attribute called
  # name, then add a reader/writer for it, name and name=, and perform the
  # parsing in name=. If there is no parsing to be done, you can simply delegate
  # the method to the underlying model.
  #
  # If the attribute is a nested form, in the writer, simply instantiate that
  # form, and pass the attributes on to it, then update the model's association
  # (if any) to reflect the changes.
  #
  # Validation is performed like on a normal model or ActiveRecord object.
  # If you have no extra validation to perform than that of the model, simply
  # delegate the validate and valid? methods to the model.
  #
  # To use nested forms, you need to add a reader and a writer. For example,
  # for a form called Person, with potentially X nested Person forms as children,
  # you would have:
  # @example
  #   class PersonForm < Form
  #     def children
  #       [@child1, @child2]
  #     end
  #
  #     def children_attributes=(attributes)
  #       ...instantiate subforms and pass attributes...
  #     end
  #   end
  class Form
    # Provides common validators and methods to add custom ones
    include ActiveModel::Validations

    # Provides translation scope and helpers (useful for error messages)
    # Also includes ActiveModel::Naming at the same time
    extend ActiveModel::Translation

    # @return [ActiveModel::Model] underlying model to populate
    attr_reader :model

    delegate :id, :persisted?, :to_key, :to_query, :to_param, :type_for_attribute, to: :model

    def initialize(model)
      @errors = ActiveModel::Errors.new(self)
      @model = model
      @form_input = {}
      @associated_forms = Hash.new { |hash, key| hash[key] = [] }
    end

    def to_model
      return @model
    end

    # @!group Attributes assignment/manipulation

    # Allows parsing of multi parameter attributes, such as those returned by
    # the form helpers date_select, datetime_select, etc.
    # Also allows nested attributes, but this is not currently in use.
    include ActiveRecord::AttributeAssignment

    # For now, we overload the method to accept all attributes.
    # This is removed in Rails 5, so once we upgrade we can remove the overload.
    def sanitize_for_mass_assignment(attributes)
      return attributes
    end

    class << self
      # Delegates the list of attributes to the model, both readers and writers.
      # If the attribute value passed is a hash and not a symbol, assumes it is
      # a hash of one key, whose value is an array contained :reader, :writer, or both.
      # @example
      #   delegate_attributes :first_name, { last_name: [:reader] }
      # @param [Array<Symbol, Hash<Symbol, Array<Symbol>>>] attributes list of attributes to delegate to the model
      def delegate_attributes(*attributes)
        delegates = attributes.each_with_object([]) do |attribute, acc|
          case attribute
          when Hash
            key, value = attribute.first
            acc << key if value.include?(:reader)
            acc << "#{key}=" if value.include?(:writer)
          when Symbol, String
            acc.push(attribute, "#{attribute}=")
          else
            raise(ArgumentError, 'Attribute must be one of: Hash, Symbol, String')
          end
        end

        delegate(*delegates, to: :model)
      end

      # Delegates a specified associations to other another form object
      # @example
      #   delegate_associations :child, :parent, to: 'Forms::PersonForm'
      def delegate_association(association, to:)
        # add a reader attribute
        class_eval <<~METHOD, __FILE__, __LINE__ + 1
          def #{association}(index = 0)
            return associated_form('#{association}', klass: '#{to}', index: index)
          end
        METHOD
      end
    end

    def associated_form(name, form_class:, index: 0)
      form_list = @associated_forms[name]
      form = form_list[index]
      if form.nil?
        form = create_associated_form(name, form_class: form_class, index: index)
        form_list[index] = form
      end

      return form
    end
    protected :associated_form

    def create_associated_form(name, form_class:, index: 0)
      klass = case form_class
      when String
        form_class.constantize
      when Class
        form_class
      end

      raise ArgumentError, 'missing associated form class' if klass.nil?
      association = @model.public_send(name)
      form_model = if association.respond_to?(:to_ary)
        association[index]
      elsif index.positive?
        raise ArgumentError, "trying to access association #{name} like a collection even if it is not"
      else
        association
      end

      return klass.new(form_model)
    end
    protected :create_associated_form

    # @!endgroup

    # @!group Validation

    validate :validate_model
    def validate_model
      unless @model.valid?
        @model.errors.each do |attribute, error|
          @errors.add(attribute, error)
        end
      end
    end
    protected :validate_model

    validate :validate_associated_forms
    def validate_associated_forms
      @associated_forms.values.flatten.each do |form|
        next if form.valid?
        form.errors.each do |_attribute, _error|
          @errors.add(:base, :association_error, "associated #{form.model_name.human} form has some errors")
        end
      end
    end
    protected :validate_associated_forms

    # @!endgroup

    # @!group Persistence

    def save
      saved = false
      @model.class.transaction do
        saved = @model.save
        @associated_forms.values.flatten do |form|
          saved &&= form.save
        end

        raise ActiveRecord::Rollback unless saved
      end

      return saved
    end

    def save!
      saved = false
      @model.class.transaction do
        saved = @model.save!
        @associated_form.values.flatten.each do |form|
          saved &&= form.save! # no need to raise anything, save! will do so
        end
      end

      return saved
    end

    # @!endgroup
  end
end
