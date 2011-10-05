module BadgesHelper
  
  BADGE_EXPLANATIONS = { 
    
    "Investigator" => "Whenever something happens, you're the first one to know.",
    "Commenter" => "You like to make your scoopinions heard.",
    "Reader" => "You're a level LEVEL news junkie.",
    "Evangelist" => "What would people read if it wasnt for you?",
    "Loyalist" => "You like to keep your feed clean.",
  }
  
  def badge_title(badge)
    if BADGE_EXPLANATIONS[badge.badge_type]
      return BADGE_EXPLANATIONS[badge.badge_type].gsub("LEVEL", badge.level.to_s)
    end

    return "Badge"
  end
  
end
