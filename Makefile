DCOMP=dmd
sliders: sliders.d
	$(DCOMP) sliders.d
clean:
	rm -f sliders sliders.o
