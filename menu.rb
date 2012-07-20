require "curses"
include Curses

def print_menu
  centerx = cols / 2 - @width / 2
  centery = lines / 2 - size / 2  
  @branches.each_with_index do |br,y|
    Curses.setpos(y + centery, centerx)
    Curses.attron(color_pair(COLOR_WHITE)|A_BOLD){
      Curses.addstr(br)
    }
  end
end

def size
  @branches.size
end

def up
  previous = @pos
  @pos -=1
  @pos %= size
  highlight(previous, @pos)
end

def down
  previous = @pos
  @pos +=1
  @pos %= size
  highlight(previous, @pos)
end

def get_branches
  ret = `git branch`
  els = ret.split("\n").
    uniq.
    delete_if{|el| el == " "}
  els.each_with_index do |el,i|
    @current = i if el.start_with? "*"
    @width = el.length if @width < el.length
  end
  els.map{|el| el.gsub(/^\s+/,"")}
end

def highlight(from, to)
  centerx = cols / 2 - @width / 2
  centery = lines / 2 - size / 2
  Curses.setpos(from + centery, centerx)  
  Curses.attron(color_pair(COLOR_WHITE)|A_BOLD){
    Curses.addstr(@branches[from] + " " * (@width - @branches[from].length))
  }  
  Curses.setpos(to + centery, centerx)
  Curses.attron(color_pair(COLOR_GREEN)|A_BOLD){
    Curses.addstr(@branches[to] + " " * (@width - @branches[to].length))
  }  
end

def menu2
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys (required for pageup/down)
  Curses.start_color
  # Determines the colors in the 'attron' below
  Curses.init_pair(COLOR_WHITE,COLOR_WHITE,COLOR_BLACK)
  Curses.init_pair(COLOR_GREEN,COLOR_WHITE,COLOR_GREEN)
  Curses.clear
  
  print_menu
  highlight(@current, @current)

  loop = true
  while loop
    case Curses.getch
    when Curses::Key::UP ; up
    when Curses::Key::DOWN ; down
    when 10 ; loop = false
    end
  end
end

@current = -1
@width = 0
@branches = get_branches
@pos = @current
menu2
selected = @branches[@pos].gsub(/[* ]/,"").gsub(" ", "")
File.open("/tmp/setbranch.sh", 'w') {|f| f.write("git checkout #{selected}") }
