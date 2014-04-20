module GroupsHelper
  def group_visibilty_options(group)
    options = []

    unless group.is_subgroup_of_hidden_parent?
      options << ['Anyone can see the group', 'public']
    end

    if group.is_subgroup?
      options << ["Members of #{group.parent_name} can see the group", "parent_members"]
    end

    options << ["Only members can see the group", "members"]

    options
  end

  def group_joining_options(group)
    if group.is_subgroup_of_hidden_parent?
      [["Anyone in #{group.parent_name} can join", 'request'],
       ["Anyone in #{group.parent_name} can request to join", 'approval'],
       ["Invitation only", 'invitation']]
    else
      [['Anyone can join', 'request'],
       ['Anyone can request to join', 'approval'],
       ['Invitation only', 'invitation']]
    end
  end

  def css_for_privacy_link(group, link)
    current_privacy_setting = String(group.privacy)
    return "icon-ok" if link == current_privacy_setting
  end

  def display_subgroups_block?(group)
    group.parent.nil? && (group.subgroups.present? || (current_user && group.users_include?(current_user)))
  end

  def show_next_steps?(group)
    user_signed_in? && current_user.is_group_admin?(group) && !group.next_steps_completed? && @group.is_parent?
  end

  def show_subscription_prompt?(group)
    user_signed_in? && current_user.is_group_admin?(group) &&
      ( group.created_at < 1.month.ago ) &&
      !group.has_subscription_plan? &&
      !group.has_manual_subscription? &&
      !group.is_subgroup?
  end

  def pending_membership_requests_count(group)
    if group.pending_membership_requests.count > 0
      t(:number_pending, pending: group.pending_membership_requests.count)
    else
      ""
    end
  end

  def members_pending_count(group)
    if group.pending_invitations.count > 0
      t(:and_number_pending, pending: group.pending_invitations.count)
    else
      ""
    end
  end

  def request_membership_button(group)
    if visitor?
      request_membership_icon_button(group)
    else
      return if group.users_include?(current_user)

      membership_request = group.membership_requests.pending.requested_by(current_user).first
      if membership_request.present?
        cancel_membership_request_button(membership_request)
      else
        request_membership_icon_button(group)
      end
    end
  end

  def disabled_request_membership_button(group)
    request_membership_icon_button(group, href: "#", class: "btn-info disabled tooltip-top",
                                   id: 'request-membership-disabled',
                                   title: "You must be a member of the parent group before you can join this subgroup.")
  end

  def cancel_membership_request_button(membership_request)
    icon_button(href: cancel_membership_request_path(membership_request),
                method: 'delete',
                text: t(:cancel_membership_request),
                icon: '/assets/group-dark.png',
                id: 'membership-requested',
                class: 'btn-grey',
                'data-confirm' => t(:confirm_remove_membership_request))
  end

  def request_membership_icon_button(group, params={})
    old_params = { href: group_ask_to_join_path(group),
                   text: t(:ask_to_join_group),
                   icon: nil,
                   id: 'request-membership',
                   class: 'btn-info' }
    new_params = old_params.merge(params)
    icon_button(new_params)
  end

  def label_and_description(label, description)
    render('groups/label_and_description', label: label, description: description)
  end

  def user_sees_private_discussions_message?(user, group)
    group.privacy == 'private' &&
    group.members.exclude?(user) &&
    group.discussions.where('private = ?', false).empty?
  end

end
