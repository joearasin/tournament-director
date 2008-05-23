class Dashboard::ConfigurationController < DashboardController

  before_filter :check_configuration, :except => ["new_tournament", "create_tournament"]

  def index
    redirect_to :action => "edit_tournament"
  end
  
  def load_tournament
    session[:tournament_id] = params['id']
    $tournament = Tournament.find(params['id'])
    load_tournament_database($tournament)
    redirect_to :action => "edit_tournament"
  end

  def new_tournament
    render :action => "_new_tournament"
  end
  
  def create_tournament
    $tournament = Tournament.create(:name => params['name'], :database => params['database'])
    session[:tournament_id] = $tournament.id
    load_tournament_database($tournament)
    redirect_to :action => "edit_tournament"
  end

  def edit_tournament
    @brackets = Bracket.find(:all, :order => "ordering, name")
    if @brackets.empty? then @brackets = [Bracket.new, Bracket.new] end
    @rooms = Room.find(:all, :order => "name")
    if @rooms.empty? then @rooms = [Room.new, Room.new] end
    
    @all_tournaments = Tournament.find(:all, :order => "id desc")
    @all_tournaments.delete($tournament)
    @tournament = $tournament
  end
  
  def save_tournament
    $tournament.update_attributes(params['tournament'])
    QuestionType.configure_for_power($tournament.powers)
    $tournament.bracketed = false if (params['bracket_names'].nil?)
    if $tournament.bracketed?
      brackets_to_delete = Bracket.find(:all)
      for name in params['bracket_names']
        next if name.empty?
        bracket = Bracket.find_or_create_by_name(name)
        brackets_to_delete.delete(bracket)
      end
      brackets_to_delete.each {|b| b.destroy}
    end
    $tournament.bracketed = false if Bracket.count == 0
    
    $tournament.save
    flash[:notice] = "Changes saved."
    redirect_to :action => "edit_tournament"
  end
  
end
