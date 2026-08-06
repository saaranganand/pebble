FLAGS := -collection:src=./src

run:
	odin run src/ $(FLAGS)

build:
	odin build src/ $(FLAGS)
