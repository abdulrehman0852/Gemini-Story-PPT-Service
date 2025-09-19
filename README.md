# AI Story Illustrator (Gemini Story & PPT Service)

**AI Story Illustrator** is a Flutter-based, cross-platform service that automatically builds engaging presentations / stories from a topic. It uses Gemini’s text + image generation APIs to create structured slide content, meaningful image prompts, and then enriches slides with generated visuals.

---

## 🚀 Features

- Generate a full presentation outline (title, description, slides) from a given topic.  
- Slides include titles, bullet-point content, and descriptive image prompts.  
- Automatically fetch/generate images for each slide.  
- Robust parsing: handles content whether Gemini returns strings or lists of bullet points.  
- Safe JSON extraction and error handling to deal with malformed or extra text from API responses.  
- Built with **Flutter** — supports Android, iOS, Web, and Desktop platforms.

---

## 🛠 Getting Started

### Prerequisites

- Flutter SDK installed  
- Dart environment properly set up  
- Access / credentials for GeminiTextService & GeminiImageService (or mocks for development)  

### Setup

1. Clone the repo:  
   ```bash
   git clone https://github.com/abdulrehman0852/Gemini-Story-PPT-Service.git
   cd Gemini-Story-PPT-Service/ai_story_illustrator
