module TagsHelper
  def alias_and_implication_list(tag)
    return "" if tag.nil?

    html = ""

    if tag.antecedent_alias
      html << "<p class='hint'>This tag has been aliased to "
      html << link_to(tag.antecedent_alias.consequent_name, show_or_new_wiki_pages_path(:title => tag.antecedent_alias.consequent_name))
      html << ".</p>"
    end

    if tag.consequent_aliases.any?
      html << "<p class='hint'>The following tags are aliased to this tag: "
      html << raw(tag.consequent_aliases.map {|x| link_to(x.antecedent_name, show_or_new_wiki_pages_path(:title => x.antecedent_name))}.join(", "))
      html << ".</p>"
    end

    if tag.antecedent_implications.any?
      html << "<p class='hint'>This tag implicates "
      html << raw(tag.antecedent_implications.map {|x| link_to(x.consequent_name, show_or_new_wiki_pages_path(:title => x.consequent_name))}.join(", "))
      html << ".</p>"
    end

    if tag.consequent_implications.any?
      html << "<p class='hint'>The following tags implicate this tag: "
      html << raw(tag.consequent_implications.map {|x| link_to(x.antecedent_name, show_or_new_wiki_pages_path(:title => x.antecedent_name))}.join(", "))
      html << ".</p>"
    end

    html.html_safe
  end
  
  def tag_post_count_style(tag)
    @highest_post_count ||= Tag.highest_post_count
    width_percent = Math.log([tag.post_count, 1].max, @highest_post_count) * 100
    "background: linear-gradient(to left, #DDD #{width_percent}%, white #{width_percent}%)"
  end
end
