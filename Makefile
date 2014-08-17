SHELL := bash

pandoc := pandoc
slide_src := src/Talk.lhs

# reveal.js parameters
reveal_js_output := revealjs/index.html
reveal_js_variables := theme=sky
reveal_js_slide_level := 2

# beamer parameters
beamer_slide_level := 2
beamer_output := beamer/talk.pdf

reveal_js_build_command := $(pandoc) -t revealjs -s $(slide_src) -o $(reveal_js_output) --slide-level $(reveal_js_slide_level) -V $(reveal_js_variables)
beamer_build_command := $(pandoc) -t beamer -s $(slide_src) -o $(beamer_output) --slide-level $(beamer_slide_level)

# Nice Shiny Colors....
# Colour table:
# \x1b[0m = No colour
# \x1b[0;32m = Green
# \x1b[0;34m = Blue
# \x1b[0;36m = Cyan
# \x1b[0;35m = Violet
# \x1b[31;01m = Red
no_colour := \x1b[0m
format_colour := \x1b[31;01m
normal_colour := \x1b[0;32m
input_colour := \x1b[0;34m
output_colour := \x1b[0;35m

.PHONY: clean

beamer: $(beamer_output)

all: revealjs beamer

$(beamer_output): $(slide_src)
	@$(beamer_build_command)
	@echo -e "$(normal_colour)[$(format_colour)beamer$(normal_colour)] $(input_colour)$(slide_src) $(normal_colour)-> $(output_colour)$(beamer_output)$(no_colour)"


revealjs: $(reveal_js_output)

$(reveal_js_output): $(slide_src)
	@$(reveal_js_build_command)
	@echo -e "$(normal_colour)[$(format_colour)reveal.js$(normal_colour)] $(input_colour)$(slide_src) $(normal_colour)-> $(output_colour)$(reveal_js_output)$(no_colour)"

clean:
	@echo -e "$(normal_colour)Cleaning up$(no_colour)"
	@rm -f $(reveal_js_output)
	@rm -f $(beamer_output)
	@echo -e "$(normal_colour)Clean$(no_colour)"

