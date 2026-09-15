function jma --description 'Morning routine: journal morning, journal start, open today journal in nvim'
    journal morning
    journal start
    nvim ~/dev/clever-brain/journal/(date +%Y)/(date +%Y-%m-%d).md
end
