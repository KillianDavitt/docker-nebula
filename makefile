html/index.html: index.md 
	pandoc -s -S -o $@ -c normalize.css $^

html/intro.html: intro.md
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/stack.html: stack.md
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/yesod.html: yesod.md 
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/nebula.html: nebula.md 
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/deploy.html: deploy.md
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/docker_hosts.html: docker_hosts.md
	pandoc -s -S --toc -o $@ -c normalize.css $^

html/swarm.html: swarm.md
	pandoc -s -S --toc -o $@ -c normalize.css $^

.PHONY: clean

clean:
	rm *.html *.pdf
