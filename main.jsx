import React, { Component } from 'react';
import { AppRegistry, Text, View, StyleSheet, TextInput, TouchableOpacity, ScrollView, Switch, Alert, Dimensions } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from 'expo-constants';

let deviceHeight = Dimensions.get('window').height;
let deviceWidth = Dimensions.get('window').width;

export default class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      assignments: [],
      newAssignment: '',
      dueDate: '',
      priority: 'Medium',
      darkMode: false,
      editIndex: null,
      currentScreen: 'home',
      journalEntry: '',
      journalEntries: [], 
      motivationalQuotes: [
        "You are capable of amazing things.",
        "Don't watch the clock; do what it does. Keep going.",
        "Believe you can and you're halfway there.",
        "Success is not final, failure is not fatal: It is the courage to continue that counts."
      ]
    };
  }

  componentDidMount() {
    this.loadAssignments();
    this.loadDarkMode();
    this.loadJournalEntries(); // Load saved journal entries
  }

  saveAssignments = async () => {
    try {
      await AsyncStorage.setItem('assignments', JSON.stringify(this.state.assignments));
    } catch (error) {
      console.log(error);
    }
  };

  loadAssignments = async () => {
    try {
      const assignments = await AsyncStorage.getItem('assignments');
      if (assignments) {
        this.setState({ assignments: JSON.parse(assignments) });
      }
    } catch (error) {
      console.log(error);
    }
  };

  saveDarkMode = async () => {
    try {
      await AsyncStorage.setItem('darkMode', JSON.stringify(this.state.darkMode));
    } catch (error) {
      console.log(error);
    }
  };

  loadDarkMode = async () => {
    try {
      const darkMode = await AsyncStorage.getItem('darkMode');
      if (darkMode !== null) {
        this.setState({ darkMode: JSON.parse(darkMode) });
      }
    } catch (error) {
      console.log(error);
    }
  };

saveJournalEntries = async () => {
    try {
      await AsyncStorage.setItem('journalEntries', JSON.stringify(this.state.journalEntries));
    } catch (error) {
      console.log(error);
    }
  };

  loadJournalEntries = async () => {
    try {
      const journalEntries = await AsyncStorage.getItem('journalEntries');
      if (journalEntries) {
        this.setState({ journalEntries: JSON.parse(journalEntries) });
      }
    } catch (error) {
      console.log(error);
    }
  };

  handleJournalChange = (text) => {
    this.setState({ journalEntry: text });
  };

addJournalEntry = () => {
  if (this.state.journalEntry.trim() !== '') {
    const newJournalEntries = [...this.state.journalEntries, this.state.journalEntry];
    this.setState({ journalEntries: newJournalEntries, journalEntry: '' }, this.saveJournalEntries);
  }
};

  handleAssignmentChange = (text) => {
    this.setState({ newAssignment: text });
  };

  handleDueDateChange = (text) => {
    this.setState({ dueDate: text });
  };

  handlePriorityChange = (text) => {
    this.setState({ priority: text });
  };

  handleJournalChange = (text) => {
    this.setState({ journalEntry: text }, this.saveJournal);
  };

  addOrEditAssignment = () => {
    if (this.state.newAssignment.trim() !== '' && this.state.dueDate.trim() !== '') {
      let updatedAssignments = [...this.state.assignments];
      if (this.state.editIndex !== null) {
        updatedAssignments[this.state.editIndex] = {
          title: this.state.newAssignment,
          dueDate: this.state.dueDate,
          priority: this.state.priority,
          completed: false,
        };
      } else {
        updatedAssignments.push({
          title: this.state.newAssignment,
          dueDate: this.state.dueDate,
          priority: this.state.priority,
          completed: false,
        });
      }
      updatedAssignments.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
      this.setState(
        { assignments: updatedAssignments, newAssignment: '', dueDate: '', priority: 'Medium', editIndex: null },
        this.saveAssignments
      );
    }
  };

  editAssignment = (index) => {
    const assignment = this.state.assignments[index];
    this.setState({ newAssignment: assignment.title, dueDate: assignment.dueDate, priority: assignment.priority, editIndex: index });
  };

  deleteAssignment = (index) => {
    const updatedAssignments = this.state.assignments.filter((_, i) => i !== index);
    this.setState({ assignments: updatedAssignments }, this.saveAssignments);
  };

  toggleDarkMode = () => {
    this.setState({ darkMode: !this.state.darkMode }, this.saveDarkMode);
  };

  renderHomeScreen = () => {
    return (
      <View>
        <TextInput
          style={[styles.input, this.state.darkMode && styles.darkInput]}
          placeholder="Enter assignment title"
          placeholderTextColor="#aaa"
          value={this.state.newAssignment}
          onChangeText={this.handleAssignmentChange}
        />
        <TextInput
          style={[styles.input, this.state.darkMode && styles.darkInput]}
          placeholder="Enter due date (YYYY-MM-DD)"
          placeholderTextColor="#aaa"
          value={this.state.dueDate}
          onChangeText={this.handleDueDateChange}
        />
        <TouchableOpacity style={styles.button} onPress={this.addOrEditAssignment}>
          <Text style={styles.buttonText}>{this.state.editIndex !== null ? 'Update Assignment' : 'Add Assignment'}</Text>
        </TouchableOpacity>
        <ScrollView style={styles.listContainer}>
          {this.state.assignments.map((assignment, index) => (
            <View key={index} style={styles.assignmentItem}>
              <Text style={[styles.assignmentTitle, assignment.completed && styles.completed, this.state.darkMode && styles.darkText]}>
                {assignment.title} ({assignment.priority})
              </Text>
              <Text style={[styles.assignmentDueDate, this.state.darkMode && styles.darkText]}>Due: {assignment.dueDate}</Text>
              <TouchableOpacity onPress={() => this.editAssignment(index)}>
                <Text style={styles.editButton}>Edit</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={() => this.deleteAssignment(index)}>
                <Text style={styles.deleteButton}>Delete</Text>
              </TouchableOpacity>
            </View>
          ))}
        </ScrollView>
      </View>
    );
  };

renderJournalScreen = () => {
  return (
    <View>
      <TextInput
        style={[styles.input, this.state.darkMode && styles.darkInput, { height: 200 }]}
        multiline
        placeholder="Write your thoughts here..."
        placeholderTextColor="#aaa"
        value={this.state.journalEntry}
        onChangeText={this.handleJournalChange}
      />
      <TouchableOpacity style={styles.button} onPress={this.addJournalEntry}>
        <Text style={styles.buttonText}>Save Journal Entry</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.button} onPress={() => this.setState({ currentScreen: 'viewJournal' })}>
        <Text style={styles.buttonText}>View Saved Entries</Text>
      </TouchableOpacity>
    </View>
  );
};

  renderViewJournalScreen = () => {
    return (
      <View>
        <Text style={[styles.header, this.state.darkMode && styles.darkText]}>Saved Journal Entries</Text>
        <ScrollView>
          {this.state.journalEntries.length > 0 ? (
            this.state.journalEntries.map((entry, index) => (
              <View key={index} style={styles.journalEntryContainer}>
                <Text style={[styles.journalText, this.state.darkMode && styles.darkText]}>{entry}</Text>
              </View>
            ))
          ) : (
            <Text style={styles.noEntriesText}>No journal entries saved yet.</Text>
          )}
        </ScrollView>
        <TouchableOpacity style={styles.button} onPress={() => this.setState({ currentScreen: 'journal' })}>
          <Text style={styles.buttonText}>Back to Journal</Text>
        </TouchableOpacity>
      </View>
    );
  };


  renderQuotesScreen = () => {
    return (
      <View>
        {this.state.motivationalQuotes.map((quote, index) => (
          <Text key={index} style={[styles.quoteText, this.state.darkMode && styles.darkText]}>{quote}</Text>
        ))}
      </View>
    );
  };

  renderActivitiesScreen = () => {
    return (
      <Text style={[styles.sectionTitle, this.state.darkMode && styles.darkText]}>Nearby student activities coming soon!</Text>
    );
  };

renderCurrentScreen = () => {
  switch (this.state.currentScreen) {
    case 'home': return this.renderHomeScreen();
    case 'journal': return this.renderJournalScreen();
    case 'viewJournal': return this.renderViewJournalScreen(); 
    case 'quotes': return this.renderQuotesScreen();
    case 'activities': return this.renderActivitiesScreen();
    default: return this.renderHomeScreen();
  }
};


  render() {
    return (
      <ScrollView style={[styles.container, this.state.darkMode && styles.darkContainer]}>
        <Text style={[styles.header, this.state.darkMode && styles.darkText]}>Student Planner</Text>
        <Switch value={this.state.darkMode} onValueChange={this.toggleDarkMode} />

        <View style={styles.navBar}>
          {['home', 'journal', 'quotes', 'activities'].map((screen) => (
            <TouchableOpacity key={screen} onPress={() => this.setState({ currentScreen: screen })}>
              <Text style={[styles.navButton, this.state.currentScreen === screen && styles.selectedNav]}>{screen}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {this.renderCurrentScreen()}
      </ScrollView>
    );
  }
}


const styles = StyleSheet.create({
  container: {
    minHeight: deviceHeight,
    paddingHorizontal: 20,
    paddingTop: 40,
    backgroundColor: '#f0f4f8', // Lighter background color
    flex: 1,
  },
  darkContainer: {
    backgroundColor: '#121212',
  },
  header: {
    fontSize: 30,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 30,
    color: '#4a90e2', // Blue accent color
    fontFamily: 'Roboto', // Add custom font if needed
  },
  darkText: {
    color: '#f0f0f0',
  },
  input: {
    height: 50,
    borderRadius: 25,
    paddingHorizontal: 20,
    marginBottom: 15,
    fontSize: 16,
    backgroundColor: '#ffffff',
    borderWidth: 1,
    borderColor: '#ddd',
    fontFamily: 'Roboto',
    shadowColor: '#ccc',
    shadowOpacity: 0.2,
    shadowOffset: { width: 0, height: 1 },
    shadowRadius: 6,
    elevation: 3,
  },
  darkInput: {
    backgroundColor: '#333',
    color: '#fff',
    borderColor: '#555',
  },
  button: {
    backgroundColor: '#4a90e2',
    paddingVertical: 16,
    borderRadius: 30,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOpacity: 0.15,
    shadowOffset: { width: 0, height: 4 },
    shadowRadius: 8,
    elevation: 5,
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '700',
    textAlign: 'center',
    fontFamily: 'Roboto',
  },
  listContainer: {
    marginTop: 15,
  },
  assignmentItem: {
    padding: 20,
    marginBottom: 15,
    backgroundColor: '#fff',
    borderRadius: 15,
    shadowColor: '#ccc',
    shadowOpacity: 0.15,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 6,
    elevation: 3,
  },
  assignmentTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 5,
    color: '#333',
  },
  completed: {
    textDecorationLine: 'line-through',
    opacity: 0.5,
  },
  assignmentDueDate: {
    fontSize: 14,
    color: '#777',
    marginBottom: 10,
  },
  deleteButton: {
    color: '#e63946',
    fontWeight: '600',
    marginTop: 10,
  },
  editButton: {
    color: '#4a90e2',
    fontWeight: '600',
    marginTop: 5,
  },
  navBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 25,
    paddingVertical: 12,
    borderRadius: 25,
    backgroundColor: '#ffffff',
    shadowColor: '#ccc',
    shadowOpacity: 0.15,
    shadowOffset: { width: 0, height: 3 },
    shadowRadius: 6,
    elevation: 3,
  },
  navButton: {
    padding: 12,
    fontWeight: '600',
    fontSize: 16,
    color: '#555',
    fontFamily: 'Roboto',
  },
  selectedNav: {
    color: '#4a90e2',
    textDecorationLine: 'underline',
  },
  quoteText: {
    fontSize: 18,
    fontStyle: 'italic',
    marginVertical: 15,
    padding: 18,
    borderRadius: 15,
    backgroundColor: '#e3f2fd',
    textAlign: 'center',
    color: '#333',
  },
  sectionTitle: {
    fontSize: 20,
    textAlign: 'center',
    paddingVertical: 30,
    fontWeight: '700',
    color: '#777',
  },
  journalEntryContainer: {
    backgroundColor: '#f9f9f9',
    borderRadius: 15,
    marginBottom: 12,
    padding: 16,
    shadowColor: '#ccc',
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 2,
  },
  journalText: {
    fontSize: 16,
    color: '#333',
    fontStyle: 'italic',
  },
  noEntriesText: {
    fontSize: 16,
    color: '#999',
    textAlign: 'center',
  },
});
