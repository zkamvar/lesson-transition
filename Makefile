DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/.git, $(INPUTS))
GITHUB  := $(patsubst %.R, sandpaper/%-status.json, $(INPUTS))
TARGETS := $(patsubst %.R, sandpaper/%.json, $(INPUTS))
PREREQS := renv/library/ template/ filter-and-transform.sh functions.R

.PHONY = all
.PHONY = modules
.PHONY = template
.PHONY = update
.PHONY = github

all: template/ $(TARGETS) repos.md
modules: $(MODULE)
template: template/
github: $(GITHUB)
update:
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::update(library = renv::paths$$library()); renv::snapshot()'

sandpaper/%-status.json : sandpaper/%.json create-test-repo.sh delete-test-repo.sh
	@bash delete-test-repo.sh $* || echo "No repository to delete"
	@NEW_TOKEN=$$(./pat.sh) bash create-test-repo.sh $* bots fishtree-attempt

renv/library/ :
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::restore()'

template/ : establish-template.R renv.lock renv/library/
	@GITHUB_PAT=$$(./pat.sh) Rscript --no-init-file $< $@

# $(MODULE) Get a submodule of a repository
%/.git : %.R
	bash fetch-submodule.sh $@

# $(TARGETS) Copy and transform a lesson
sandpaper/%.json : %.R %/.git $(PREREQS) transform-lesson.R
	bash filter-and-transform.sh $@ $<

sandpaper/datacarpentry/R-ecology-lesson.json : datacarpentry/R-ecology-lesson.R datacarpentry/R-ecology-lesson/.git $(PREREQS)
	bash filter-and-transform.sh $@ $<

repos.md : $(TARGETS)
	@rm -f repos.md
	@for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.json//');\
	 slug=$$(basename $${repo}));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [fishtree-attempt/$${slug}](https://github.com/fishtree-attempt/$${slug})" >> $@;\
	 done



