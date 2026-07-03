FLAGS := -define:YAML_STATIC=true

run:
	odin run src/ $(FLAGS)

build:
	odin build src/ $(FLAGS)
