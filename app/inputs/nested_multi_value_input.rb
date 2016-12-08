# add in a nested-field class
class NestedMultiValueInput < MultiValueInput

  protected
    def inner_wrapper
      <<-HTML
          <li class="field-wrapper nested-field">
            #{yield}
          </li>
        HTML
    end
end
