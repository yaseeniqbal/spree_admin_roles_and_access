module Spree
  module Permissions
    def method_missing(name, *args, &block)
      if name.to_s.starts_with?('can')
        

        Permissions.send(:define_method, name) do |current_ability, user|
          can, action, subject, attribute , check = find_action_and_subject.call(name,user)

          if check.blank?
            check = {}
          end
          if attribute.nil?
            current_ability.send(can, action, subject,check)
          else
            current_ability.send(can, action, subject, attribute,check)
          end
        end
        send(name, args[0], args[1]) if self.respond_to?(name)
      else
        super
      end
    end

    define_method('default-permissions') do |current_ability, user|
      current_ability.can [:read, :update, :destroy], Spree.user_class

      current_ability.can [:read, :update], Spree::Order, { user_id: user.id }

      current_ability.can :create, Spree::Order

      current_ability.can :read, Spree::Order, [] do |order, token|
        order.user == user || (order.guest_token && token == order.guest_token)
      end

      current_ability.can :update, Spree::Order do |order, token|
        !order.completed? && (order.user == user || order.guest_token && token == order.guest_token)
      end

      current_ability.can :read, Spree::Address do |address|
        address.user == user
      end
      current_ability.can [:read], Spree::State
      current_ability.can [:read], Spree::Country

      # current_ability.cannot :read, Spree::Order, [] do |order, token|
      #   order.completed? && order.parent_order_id.blank?
      # end

      current_ability.cannot :update, Spree::Order do |order, token|
        order.completed? && order.parent_order_id.blank?
      end
    end

    define_method('default-admin-permissions') do |current_ability, user|
      current_ability.can :admin, Spree::Store
    end

    define_method('can-update-spree/users') do |current_ability, user|
      current_ability.can :update, Spree.user_class
      # The permission of cannot update role_ids was given to user so that no one with this permission can change role of user.
      current_ability.cannot :update, Spree.user_class, :role_ids
    end

    define_method('can-create-spree/users') do |current_ability, user|
      current_ability.can :create, Spree.user_class
      current_ability.cannot :create, Spree.user_class, :role_ids
    end

    define_method('can-manage-spree/config') do |current_ability, user|
      current_ability.can :manage, Spree::Config
    end

    define_method('can-admin-spree/config') do |current_ability, user|
      current_ability.can :admin, Spree::Config
    end

    private
      def find_action_and_subject
        lambda do |name,user|
          #for vendor name will be like "can-admin-spree/products#vendor-product"
          name_default,vendor_data = name.to_s.split('#')

          if vendor_data.present?
            vendor = vendor_data.split('-').first
            vendor_ids = user.vendors.pluck(:id)
            vendor_key = vendor_data.split('-').last
          end

          vendorDef = {
            default: {vendor_id:vendor_ids},
            product: {vendor_id:vendor_ids},
            order: {vendor_id:vendor_ids},
            price:   {variant: { vendor_id: vendor_ids }},
            option_type:   {vendor_id:vendor_ids},
            shipment: {order: {vendor_id: vendor_ids}},
            vendor_translation: {spree_vendor_id:vendor_ids}
          }

          can, action, subject, attribute = name_default.split('-')

          if subject == 'all'
            if vendor.present? && vendor == 'vendor'
              vendor_def = vendorDef[vendor_key.to_sym]||vendorDef['default']
              return can.to_sym, action.to_sym, subject.to_sym, attribute.try(:to_sym), vendor_def
            else
              return can.to_sym, action.to_sym, subject.to_sym, attribute.try(:to_sym)
            end
          elsif (subject_class = subject.classify.safe_constantize) && subject_class.respond_to?(:ancestors)
            if vendor.present? && vendor == 'vendor'
              if vendor_key == 'order'
              end
              vendor_def = vendorDef[vendor_key.to_sym]||vendorDef['default']
              return can.to_sym, action.to_sym, subject_class, attribute.try(:to_sym), vendorDef[vendor_key.to_sym]
              #return can.to_sym, action.to_sym, Spree::Product, vendorDef[vendor_key.to_sym]
            else
              return can.to_sym, action.to_sym, subject_class, attribute.try(:to_sym)
            end
          else
            if vendor.present? && vendor == 'vendor'
              vendor_def = vendorDef[vendor_key.to_sym]||vendorDef['default']
              return can.to_sym, action.to_sym, subject, attribute.try(:to_sym), vendor_def
            else
              return can.to_sym, action.to_sym, subject, attribute.try(:to_sym)
            end
          end
        end
      end
  end
end
